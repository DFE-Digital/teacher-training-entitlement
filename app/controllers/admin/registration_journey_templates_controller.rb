module Admin
  class RegistrationJourneyTemplatesController < AdminController
    before_action :require_super_admin
    before_action :registration_journey

    def new
      load_registration_templates
    end

    def create
      @registration_template = RegistrationTemplate.find_by(id: params[:registration_template_id])

      unless applicable_registration_template?
        load_registration_templates
        flash.now[:alert] = {
          title: "Registration template could not be applied",
          message: "Select a registration template with a valid template-generating service.",
        }
        render :new, status: :unprocessable_content
        return
      end

      apply_registration_template!

      redirect_to admin_registration_journey_path(registration_journey),
                  flash: { success: "Registration template applied" }
    end

  private

    def registration_journey
      @registration_journey ||= RegistrationJourney.find(params[:registration_journey_id])
    end

    def load_registration_templates
      @registration_templates = RegistrationTemplate.order(:name, :id)
    end

    def applicable_registration_template?
      return false unless @registration_template

      service_class_name = @registration_template.template_generating_service_class
      service_class_name.present? && service_class_name.in?(@registration_template.template_generating_services)
    end

    def apply_registration_template!
      RegistrationJourney.transaction do
        registration_journey.lock!
        clazz = @registration_template.template_generating_service_class.constantize
        service = clazz.new(registration_journey:, registration_template: @registration_template)
        service.call
      end
    end
  end
end
