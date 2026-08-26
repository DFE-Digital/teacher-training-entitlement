module Admin
  class RegistrationTemplateJourneysController < AdminController
    before_action :require_super_admin
    before_action :registration_template

    def create
      @registration_journey = RegistrationJourney.new(registration_journey_params)

      unless applicable_registration_template?
        redirect_to admin_registration_template_path(registration_template),
                    flash: { alert: "Registration template has no valid template-generating service" }
        return
      end

      RegistrationJourney.transaction do
        @registration_journey.save!
        apply_registration_template!
      end

      redirect_to admin_registration_journey_path(@registration_journey),
                  flash: { success: "Registration journey created from template" }
    rescue ActiveRecord::RecordInvalid
      render "admin/registration_templates/show", status: :unprocessable_content
    end

  private

    def registration_template
      @registration_template ||= RegistrationTemplate.find(params[:registration_template_id])
    end

    def registration_journey_params
      params.require(:registration_journey).permit(:name, :slug)
    end

    def applicable_registration_template?
      service_class_name = registration_template.template_generating_service_class
      service_class_name.present? && service_class_name.in?(registration_template.template_generating_services)
    end

    def apply_registration_template!
      clazz = registration_template.template_generating_service_class.constantize
      service = clazz.new(registration_journey: @registration_journey, registration_template:)
      service.call
    end
  end
end
