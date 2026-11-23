require "api_v2_path"

class ErrorsController < PublicPagesController
  JSON_API_CONTENT_TYPE = "application/vnd.api+json".freeze

  layout "application"

  before_action :set_format

  def not_found
    return render_json_api_error(:not_found, "Resource not found") if api_v2_request?

    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: "Resource not found" }, status: :not_found }
      format.all { render status: :not_found, body: nil }
    end
  end

  def internal_server_error
    return render_json_api_error(:internal_server_error, "Internal server error") if api_v2_request?

    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
      format.all { render status: :internal_server_error, body: nil }
    end
  end

  def unprocessable_content
    return render_json_api_error(:unprocessable_content, "Unprocessable entity") if api_v2_request?

    respond_to do |format|
      format.html { render status: :unprocessable_content }
      format.json { render json: { error: "Unprocessable entity" }, status: :unprocessable_content }
      format.all { render status: :unprocessable_content, body: nil }
    end
  end

private

  def set_format
    request.format = :json if request.original_fullpath =~ %r{^/api/(?!docs|guidance)} && request.format.html?
  end

  # API V2 errors raised outside its controllers are still JSON:API documents.
  def api_v2_request?
    APIV2Path.match?(request.original_fullpath)
  end

  def render_json_api_error(status, title)
    code = Rack::Utils.status_code(status)

    render json: { errors: [{ status: code.to_s, title: }] }, status: code, content_type: JSON_API_CONTENT_TYPE
  end
end
