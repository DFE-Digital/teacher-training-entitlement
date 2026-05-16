class ReceptionRegistrationsController < LoggedInController
  helper_method :current_step, :previous_step, :current_step_name
  delegate :current_step, :previous_step, :current_step_name, to: :wizard

  def show
    # DfE Wizard does not support exiting the wizard from the #show action
    # and redirecting to another page
    # so we add an 'exit' step and then check for it here.
    if current_step_name == :exit || wizard.next_step == :exit
      redirect_to reception_registration_path(:start) and return
    end

    # DfE Wizard does not support overriding the current step
    # when a form is invalid on #show
    # so we have to ask our step strategy what the current step should be
    # and redirect if it doesn't match the current step
    # Use case would be when a user lands on a step before having
    # been through previous steps and filling in necessary data,
    # e.g. check-answers before choose-provider
    if wizard.next_step_name.present?
      redirect_to reception_registration_path(wizard.next_step_name) and return
    end

    @step = wizard.current_step
  end

  def update
    unless wizard.save_current_step
      @step = wizard.current_step
      render :show and return
    end

    update_service&.call

    redirect_to reception_registration_path(wizard.next_step || :exit)
  end

private

  def update_service
    @update_service ||= ReceptionRegistrations::ServiceStrategy.for(wizard:, user: current_user)
  end

  def should_exit?
    wizard.next_step == :exit || current_step_name == :exit
  end

  def wizard
    @wizard ||= ::ReceptionRegistrations::FormWizard.new(
      params:, session:, user: current_user,
      action_type: action_name.to_sym
    )
  end
end
