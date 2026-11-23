module API
  module V2
    # Renders JSON:API documents and JSON:API error objects.
    # API V2 is only reachable while the API V2 feature flag is enabled.
    class BaseController < API::BaseController
      CONTENT_TYPE = "application/vnd.api+json".freeze

      before_action :ensure_api_v2_enabled

    private

      def ensure_api_v2_enabled
        render_endpoint_not_found unless Feature.api_v2_enabled?
      end

      def render_endpoint_not_found
        render_errors(
          status: :not_found,
          title: I18n.t(:endpoint_not_found),
          details: "#{request.method} #{request.path}",
        )
      end

      def render_document(document, status: :ok)
        render json: document, status:, content_type: CONTENT_TYPE
      end

      def render_errors(status:, title:, details:)
        errors = Array(details).map do |detail|
          { status: Rack::Utils.status_code(status).to_s, title:, detail: }
        end

        render json: { errors: }, status:, content_type: CONTENT_TYPE
      end

      def unpermitted_parameter_response(exception)
        render_errors(status: :unprocessable_content, title: I18n.t(:unpermitted_parameters), details: exception.params)
      end

      def forbidden_response(exception)
        render_errors(status: :forbidden, title: I18n.t(:forbidden), details: exception.message)
      end

      def bad_request_response(exception)
        # Ordinary request validation errors are not reported.
        Sentry.capture_exception(exception) unless exception.is_a?(ActionController::BadRequest)
        render_errors(status: :bad_request, title: I18n.t(:bad_request), details: exception.message)
      end

      def record_not_found(_exception)
        render_errors(status: :not_found, title: I18n.t(:resource_not_found), details: I18n.t(:resource_not_found))
      end

      def filter_validation_error_response(exception)
        render_errors(status: :unprocessable_content, title: I18n.t(:unpermitted_parameters), details: exception.message)
      end
    end
  end
end
