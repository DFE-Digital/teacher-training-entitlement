class WebhooksController < ActionController::API
  class ForbiddenError < StandardError; end

  before_action :set_cache_headers
  before_action :remove_charset
  before_action :set_sentry_context
  before_action :authenticate

  include ActionController::MimeResponds
  include ActionController::HttpAuthentication::Token::ControllerMethods

  include DfE::Analytics::Requests

  rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
  rescue_from ActionController::BadRequest, with: :bad_request_response
  rescue_from ArgumentError, with: :bad_request_response
  rescue_from ForbiddenError, with: :forbidden_response
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

private

  def authenticate
    authenticate_with_http_token do |unhashed_token|
      @current_api_token = APIToken.find_by_unhashed_token(unhashed_token, scope: :teacher_record_service)
      if @current_api_token
        @current_api_token.update!(last_used_at: Time.zone.now)
      else
        raise ForbiddenError, "token not found"
      end
    end
  end

  def set_cache_headers
    no_store
  end

  def set_sentry_context
    Sentry::Metrics.count(
      "webhook.request",
      value: 1,
      attributes: {
        path: [params[:controller], params[:action]].join("#"),
        method: request.method,
      },
    )

    Sentry.configure_scope do |scope|
      scope.set_tag("webhook", true)
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
end
