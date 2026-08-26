module Admin
  class RegistrationStepCustomViewsController < AdminController
    before_action :require_super_admin
    before_action :registration_journey
    before_action :registration_step

    def create
      update_custom_view
    end

    def update
      update_custom_view
    end

  private

    def update_custom_view
      registration_step.set_custom_view!(custom_view_class_name: params[:custom_view])

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
