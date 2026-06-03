module API
  class BaseController < ActionController::API
    class ForbiddenError < StandardError; end

    before_action :set_cache_headers
    before_action :remove_charset
    before_action :set_sentry_context

    include ActionController::MimeResponds
    include API::LoggerPayload

    include DfE::Analytics::Requests

    rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
    rescue_from ActionController::BadRequest, with: :bad_request_response
    rescue_from ArgumentError, with: :bad_request_response
    rescue_from ForbiddenError, with: :forbidden_response
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from API::Errors::FilterValidationError, with: :filter_validation_error_response

  private

    def current_lead_provider
      # set with ApiAuthentication middleware
      request.env["current_lead_provider"]
    end

    def set_sentry_context
      return unless current_lead_provider

      Sentry::Metrics.count(
        "api.request",
        value: 1,
        attributes: {
          id: current_lead_provider.id,
          name: current_lead_provider.name,
          path: [params[:controller], params[:action]].join("#"),
          method: request.method,
        },
      )

      Sentry.configure_scope do |scope|
        scope.set_tag("api", true)
        scope.set_tag("lead_provider.id", current_lead_provider.id)
        scope.set_tag("lead_provider.name", current_lead_provider.name)
        scope.set_user(id: current_lead_provider.id, username: current_lead_provider.name)
        scope.set_context("lead_provider", { id: current_lead_provider.id, name: current_lead_provider.name })
      end
    end

    def remove_charset
      ActionDispatch::Response.default_charset = nil
    end

    def unpermitted_parameter_response(exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:unpermitted_parameters), params: exception.params).call }, status: :unprocessable_content
    end

    def forbidden_response(exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:forbidden), params: exception.message).call }, status: :forbidden
    end

    def bad_request_response(exception)
      Sentry.capture_exception(exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:bad_request), params: exception.message).call }, status: :bad_request
    end

    def record_not_found(_exception)
      render json: { error: I18n.t(:resource_not_found) }, status: :not_found
    end

    def filter_validation_error_response(exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:unpermitted_parameters), params: exception.message).call }, status: :unprocessable_content
    end

    def api_token_scope
      APIToken.scopes[:lead_provider]
    end

    def set_cache_headers
      no_store
    end

    def check_participant_id_change
      return unless (participant_id_change = ParticipantIdChange.find_by(from_participant_id: params[:ecf_id]))

      errors = [{
        title: "Participant ID has been changed",
        detail: I18n.t("participant_id_changed", **participant_id_change.i18n_params),
        participant_id_changes: [API::ParticipantIdChangeSerializer.render_as_hash(participant_id_change)],
      }]

      render json: { errors: }, status: :gone
    end
  end
end
