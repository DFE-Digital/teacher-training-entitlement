module Admin
  class RegistrationStepAnswersController < AdminController
    before_action :require_super_admin
    before_action :registration_journey, only: %i[create update destroy]
    before_action :registration_step, only: %i[create update destroy]

    def index
      render partial: "admin/registration_step_answers/registration_step_answer",
             locals: { registration_step: registration_step, type: params[:type] }
    end

    def create
      registration_step.add_answer!(
        answer_name: params[:answer_name],
        answer_value: params[:answer_value],
        next_step_id: next_step_id(params[:next_step_id]),
        redirect_path: params[:redirect_path],
        redirect_state_store_key: params[:redirect_state_store_key],
      )

      redirect_to edit_admin_registration_journey_registration_step_path(
        registration_journey,
        registration_step,
      )
    end

    def update
      registration_step.set_answers!(answers: answer_params)

      redirect_to edit_admin_registration_journey_registration_step_path(
        registration_journey,
        registration_step,
      )
    end

    def destroy
      registration_step.remove_answer!(index: params.require(:index))

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
      @registration_step ||= RegistrationStep.find_by(id: params[:registration_step_id])
    end

    def answer_params
      params.fetch(:answers, {}).values.map do |answer|
        answer.merge(
          "next_step_id" => next_step_id(answer["next_step_id"]),
          "redirect_path" => answer["redirect_path"],
          "value" => answer["value"],
        )
      end
    end

    def next_step_id(value)
      value.presence&.to_i
    end
  end
end
