module Admin
  class RegistrationStepCustomStepsController < AdminController
    before_action :require_super_admin
    before_action :registration_journey
    before_action :registration_step

    def create
      update_custom_step
    end

    def update
      update_custom_step
    end

  private

    def update_custom_step
      registration_step.set_custom_step!(custom_step_class_name: params[:custom_step])

      redirect_to edit_admin_registration_journey_registration_step_path(
        registration_journey,
        registration_step,
      )
    end

    def registration_journey
      @registration_journey ||= RegistrationJourney.find(params[:registration_journey_id])
    end

    def registration_step
      @registration_step ||= registration_journey.registration_steps.find(params[:registration_step_id])
    end
  end
end
