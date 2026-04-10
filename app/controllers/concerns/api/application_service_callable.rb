module API
  module ApplicationServiceCallable
    extend ActiveSupport::Concern

    def call_application_service_and_render(service:, application:)
      if application.nil?
        service.errors.add(:base, :application_not_found)
      elsif application.superceded_status?
        service.errors.add(:base, :application_superceded)
      else
        service.call
      end

      if service.errors.blank?
        render json: yield
      else
        render json: API::Errors::Response.from(service), status: error_status_for(application:)
      end
    end

  private

    def error_status_for(application:)
      if application.nil?
        :not_found
      elsif application.superceded_status?
        :forbidden
      else
        :unprocessable_content
      end
    end
  end
end
