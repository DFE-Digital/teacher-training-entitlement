module API
  module ServiceCallable
    extend ActiveSupport::Concern

    def call_application_service_and_render(service:)
      service.call

      if service.errors.blank?
        render json: yield
      else
        render json: API::Errors::Response.from(service), status: :unprocessable_content
      end
    end
  end
end
