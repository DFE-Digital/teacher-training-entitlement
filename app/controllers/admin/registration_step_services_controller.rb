module Admin
  class RegistrationStepServicesController < AdminController
    before_action :require_super_admin
    before_action :registration_journey
    before_action :registration_step

    def create
      if registration_step.set_service!(
        class_name: service_params[:service_class],
        execute_point: service_params[:execute_point].presence || RegistrationStep::DEFAULT_SERVICE_EXECUTE_POINT,
      )
        flash[:success] = "Registration step service updated"
      else
        flash[:alert] = "Select a service and when it should run"
      end

      redirect_to edit_admin_registration_journey_registration_step_path(
        registration_journey,
        registration_step,
      )
    end

  private

    def registration_journey
      @registration_journey ||= RegistrationJourney.find(params[:registration_journey_id])
    end

    def registration_step
      @registration_step ||= registration_journey.registration_steps.find(params[:registration_step_id])
    end

    def service_params
      @service_params ||= begin
        nested_params = params[:registration_step_service] || params[:service] || {}

        {
          service_class: params[:service_class].presence || nested_params[:service_class],
          execute_point: params[:execute_point].presence || nested_params[:execute_point],
        }
      end
    end
  end
end
