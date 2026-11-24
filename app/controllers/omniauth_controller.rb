class OmniauthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: %i[teacher_auth]
  skip_before_action :authenticate_teacher!

  def one_login
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_started, request:)

    redirect_to teacher_teacher_auth_omniauth_authorize_path, status: :temporary_redirect
  end

  def teacher_auth
    provider_data = request.env["omniauth.auth"]

    # Store id_token for OIDC logout (required as id_token_hint parameter)
    session[:id_token] = provider_data.credentials.id_token

    @teacher = Teachers::FindOrCreateFromTeacherAuth.new(
      provider_data:,
      feature_flag_id: session["feature_flag_id"],
    ).call

    session["teacher_id"] = @teacher.id
    @teacher.set_closed_registration_feature_flag
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_completed, request:, user: @teacher)
    sign_in_and_redirect @teacher
  rescue StandardError => e
    Rails.logger.info("[TeacherAuth] #{e} raised, teacher_id=#{@teacher.try(:id)} uid=#{try_to_extract_teacher_uid}")
    Sentry.capture_exception(e)
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_failed, request:, data: { error_type: "callback_error" })

    flash[:error] = failure_message
    redirect_to failed_sign_in_path
  end

  def failure
    redirect_to after_sign_in_path_for(current_teacher) and return if logged_in_teacher.present?

    Rails.logger.info("[TeacherAuth][omniauth_failure] uid=#{try_to_extract_teacher_uid} error=#{try_to_extract_error_type}")
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_failed, request:, data: { error_type: try_to_extract_error_type })
    send_error_to_sentry(
      "Omniauth login failure (#{try_to_extract_error_type})",
      contexts: {
        "OmniAuth" => {
          error_type: try_to_extract_error_type.to_s,
          error: request.env["omniauth.error"].inspect,
          strategy: request.env["omniauth.error.strategy"]&.name,
          origin: request.env["omniauth.origin"],
          uid: try_to_extract_teacher_uid,
        },
      },
    )

    flash[:error] = failure_message
    redirect_to failed_sign_in_path
  end

private

  def send_error_to_sentry(message, contexts: {})
    Sentry.with_scope do |scope|
      contexts.each do |context_name, context|
        scope.set_context(context_name, context)
      end

      exception = RuntimeError.new(message)
      Sentry.capture_exception(exception)
    end
  end

  def failure_message
    "There was an error. Please try again in a few moments. If this problem persists, contact us at continuing-professional-development@digital.education.gov.uk"
  end

  def failed_sign_in_path
    registration_wizard_show_path(:start)
  end

  def after_sign_in_path_for(teacher)
    if request.env["omniauth.params"] &&
        request.env["omniauth.params"]["request_email_updates"] == "true"
      return new_email_update_path
    end

    start_questionnaire_path(teacher)
  end

  def start_questionnaire_path(teacher)
    wizard = RegistrationWizard.new(
      current_step: :auth_callback,
      store: session["registration_store"],
      params: {},
      request:,
      current_teacher: teacher,
    )

    registration_wizard_show_path(wizard.next_step_path)
  end

  def try_to_extract_teacher_uid
    request.env["omniauth.auth"].uid
  rescue StandardError
    "unknown-provider-uid"
  end

  def try_to_extract_error_type
    request.env["omniauth.error.type"]
  rescue StandardError
    "unknown-error-type"
  end
end
