class OmniauthController < Devise::OmniauthCallbacksController
  REGISTRATION_SESSION_KEY = "registration_sign_in".freeze

  skip_before_action :verify_authenticity_token, only: %i[teacher_auth]
  skip_before_action :authenticate_user!

  def one_login
    remember_registration_sign_in
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_started, request:)

    redirect_to user_teacher_auth_omniauth_authorize_path, status: :temporary_redirect
  end

  def teacher_auth
    provider_data = request.env["omniauth.auth"]

    # Store id_token for OIDC logout (required as id_token_hint parameter)
    session[:id_token] = provider_data.credentials.id_token

    @user = Users::FindOrCreateFromTeacherAuth.new(
      provider_data:,
      feature_flag_id: session["feature_flag_id"],
    ).call

    session["user_id"] = @user.id
    @user.set_closed_registration_feature_flag
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_completed, request:, user: @user)
    sign_in_and_redirect @user
  rescue StandardError => e
    Rails.logger.info("[TeacherAuth] #{e} raised, user_id=#{@user.try(:id)} uid=#{try_to_extract_user_uid}")
    Sentry.capture_exception(e)
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_failed, request:, data: { error_type: "callback_error" })

    flash[:error] = failure_message
    redirect_to failed_sign_in_path
  end

  def failure
    redirect_to after_sign_in_path_for(current_user) and return if logged_in_user.present?

    Rails.logger.info("[TeacherAuth][omniauth_failure] uid=#{try_to_extract_user_uid} error=#{try_to_extract_error_type}")
    StreamAnalyticsEventToBigQueryJob.send_event(type: :one_login_failed, request:, data: { error_type: try_to_extract_error_type })
    send_error_to_sentry(
      "Omniauth login failure (#{try_to_extract_error_type})",
      contexts: {
        "OmniAuth" => {
          error_type: try_to_extract_error_type.to_s,
          error: request.env["omniauth.error"].inspect,
          strategy: request.env["omniauth.error.strategy"]&.name,
          origin: request.env["omniauth.origin"],
          uid: try_to_extract_user_uid,
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

  # The new registration journey: remember the course and where to go once signed in.
  def remember_registration_sign_in
    session.delete(REGISTRATION_SESSION_KEY)
    course = Course.find_by(identifier: params[:course_identifier]) if params[:course_identifier].present?
    return unless course && Feature.registration_dfe_wizard?

    wizard = Registration::Wizard.for_session(course:, session:, current_user: nil, current_step: :sign_in)
    session[REGISTRATION_SESSION_KEY] = { "course_identifier" => course.identifier, "next_step_path" => wizard.next_step_path }
  end

  def failed_sign_in_path
    course = Course.find_by(identifier: session.delete(REGISTRATION_SESSION_KEY)&.dig("course_identifier"))
    return registration_wizard_show_path(:start) unless course

    registration_step_path(course_identifier: course.identifier, step: "sign-in")
  end

  def after_sign_in_path_for(user)
    registration_path = session.delete(REGISTRATION_SESSION_KEY)&.dig("next_step_path")
    return registration_path if registration_path.present?

    if request.env["omniauth.params"] &&
        request.env["omniauth.params"]["request_email_updates"] == "true"
      return new_email_update_path
    end

    start_questionnaire_path(user)
  end

  def start_questionnaire_path(user)
    wizard = RegistrationWizard.new(
      current_step: :auth_callback,
      store: session["registration_store"],
      params: {},
      request:,
      current_user: user,
    )

    registration_wizard_show_path(wizard.next_step_path)
  end

  def try_to_extract_user_uid
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
