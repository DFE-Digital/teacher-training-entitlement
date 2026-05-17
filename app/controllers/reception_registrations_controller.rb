class ReceptionRegistrationsController < LoggedInController
  skip_before_action :authenticate_user!, only: %i[show development_login]
  before_action :authenticate_user_unless_public_step, only: :show
  before_action :redirect_to_closed_registration, only: %i[show update], unless: :closed_step?

  helper_method :current_step, :previous_step, :current_step_name
  delegate :current_step, :previous_step, :current_step_name, to: :wizard

  def show
    if public_step?
      @step_name = Feature.registration_closed?(current_user) ? :closed : params.fetch(:step, :start)
      render :show and return
    end

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

    wizard.ensure_funding_eligibility! if current_step_name == :"ineligible-for-funding"

    @step = wizard.current_step
  end

  def update
    unless wizard.save_current_step
      @step = wizard.current_step
      render :show and return
    end

    result = update_service&.call

    if result.is_a?(Application)
      redirect_to application_path(result.ecf_id) and return
    end

    redirect_to reception_registration_path(wizard.next_step || :exit)
  end

  def development_login
    return head :not_found unless Rails.env.development? || Rails.env.review?

    user = User.find_by!(email: params[:user_email])
    session["user_id"] = user.id
    sign_in user

    redirect_to reception_registration_path(params.fetch(:step, "course-start-date"))
  end

private

  def update_service
    @update_service ||= ReceptionRegistrations::ServiceStrategy.for(wizard:, user: current_user)
  end

  def authenticate_user_unless_public_step
    authenticate_user! unless public_step?
  end

  def public_step?
    params.fetch(:step, :start).to_s.in?(%w[start closed])
  end

  def closed_step?
    params[:step].to_s == "closed"
  end

  def redirect_to_closed_registration
    redirect_to reception_registration_path("closed") if Feature.registration_closed?(current_user)
  end

  def wizard
    @wizard ||= ::ReceptionRegistrations::FormWizard.new(
      params:, session:, user: current_user,
      action_type: action_name.to_sym
    )
  end
end
