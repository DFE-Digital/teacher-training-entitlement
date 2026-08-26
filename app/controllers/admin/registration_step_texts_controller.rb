module Admin
  class RegistrationStepTextsController < AdminController
    before_action :require_super_admin
    before_action :registration_journey
    before_action :registration_step

    def show; end

    def create
      registration_step.add_text!(
        text: params.require(:text),
        text_size: params[:text_size].presence || "m",
      )

      redirect_to edit_admin_registration_journey_registration_step_path(
        registration_journey,
        registration_step,
      ), flash: { success: "Registration step text added" }
    end

    def destroy
      registration_step.remove_text!(index: params.require(:index))

      redirect_to edit_admin_registration_journey_registration_step_path(
        registration_journey,
        registration_step,
      ), flash: { success: "Registration step text deleted" }
    end

  private

    def registration_journey
      @registration_journey ||= RegistrationJourney.find(params[:registration_journey_id])
    end

    def registration_step
      @registration_step ||= registration_journey.registration_steps.find(params[:registration_step_id])
    end
  end
end
