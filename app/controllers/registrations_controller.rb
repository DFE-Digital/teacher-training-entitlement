class RegistrationsController < LoggedInController
  helper_method :current_step, :previous_step, :current_step_name
  delegate :current_step, :previous_step, :current_step_name, to: :wizard

  def show
    # DfE Wizard does not support exiting the wizard from the #show action
    # and redirecting to another page
    # so we add an 'exit' step and then check for it here.

    redirect_to root_path and return if should_exit?

    (registration_step.services_to_run(execute_point: :before_show) + registration_step.services_to_run(execute_point: :before_step)).each do |service_class|
      service_class.constantize.new(wizard:).call
    end

    @step = wizard.current_step
  end

  def update
    unless wizard.save_current_step
      @step = wizard.current_step
      render :show and return
    end

    wizard.store_current_step_answers

    registration_step.services_to_run(execute_point: :after_update).each do |service_class|
      service_class.constantize.new(wizard:).call
    end

    redirect_target = registration_step.redirect_target_for(
      answer: submitted_answer,
      state_store: wizard.state_store,
    )

    redirect_to redirect_target and return if redirect_target

    # set_flash
    redirect_to registration_path(params[:journey_slug], wizard.next_step || :exit)
  end

private

  def should_exit?
    wizard.next_step == :exit || current_step_name == :exit
  end

  def wizard
    @wizard ||= FormWizard.new(
      params:, session:,
      registration_journey:,
      registration_step:
    )
  end

  def registration_journey
    @registration_journey ||= RegistrationJourney.find_by_slug(params[:journey_slug])
  end

  def registration_step
    @registration_step ||= if params[:step_slug].nil?
                             registration_journey.registration_steps.first
                           else
                             registration_journey.registration_steps.find_by_slug(params[:step_slug])
                           end
  end

  def submitted_answer
    params.dig(current_step_name, :step_answer) || params[:step_answer]
  end

  # def set_flash
  #   return unless current_step_name == :"check-answers"

  #   if update_service.errors.any?
  #     flash[:alert] = {
  #       title: I18n.t("applications.change_provider.check_answers.fail.title"),
  #       message: update_service.errors.full_messages.to_sentence,
  #     }
  #   else
  #     flash[:success] = {
  #       title: I18n.t("applications.change_provider.check_answers.success.title"),
  #       message: I18n.t("applications.change_provider.check_answers.success.message"),
  #     }
  #   end
  # end
end
