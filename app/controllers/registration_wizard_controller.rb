class RegistrationWizardController < PublicPagesController
  before_action :registration_closed
  before_action :set_wizard
  before_action :set_form
  before_action :check_end_of_journey, only: %i[update]
  before_action :check_duplicate_applications, only: %i[update]

  rescue_from FundingEligibility::MissingMandatoryInstitution, with: :redirect_to_work_setting
  rescue_from RegistrationWizard::RemovedStep, with: :redirect_to_course_start_date

  helper_method :course

  def show
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    @wizard.before_render

    return redirect_to registration_wizard_show_path(@wizard.next_step_path) if @wizard.skip_step?
    return redirect_to root_path unless @form.requirements_met?

    render @wizard.current_step

    @wizard.after_render
  end

  def update
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    return redirect_to registration_wizard_show_path(@wizard.next_step_path) if @wizard.skip_step?
    return redirect_to root_path unless @form.requirements_met?

    if @form.valid?
      if @form.redirect_to_change_path?
        redirect_to registration_wizard_show_change_path(@wizard.next_step_path)
      else
        redirect_to registration_wizard_show_path(@wizard.next_step_path)
      end

      @wizard.save!
    else
      render @wizard.current_step
    end
  end

  def development_login
    return unless Rails.env.development? || Rails.env.review?

    # user_email = ENV["DEV_USER_EMAIL_FOR_LOGIN"]
    user = User.find_by!(email: params[:user_email])
    session["user_id"] = user.id
    sign_in user
    wizard = RegistrationWizard.new(
      current_step: :auth_callback,
      store: session["registration_store"],
      params: {},
      request:,
      current_user: user,
    )

    redirect_to registration_wizard_show_path(wizard.next_step_path)
  end

private

  def redirect_to_course_start_date
    redirect_to registration_wizard_show_path("course-start-date")
  end

  def redirect_to_work_setting
    redirect_to registration_wizard_show_path("work-setting")
  end

  def set_wizard
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore, store:, params: wizard_params, request:, current_user:)
  end

  def set_form
    @form = @wizard.form
  end

  def check_duplicate_applications
    return unless @wizard.current_step.to_s == "choose_your_provider" && @form.lead_provider_id.present?

    active_applications = current_user.active_applications_for(course:, cohort: Cohort.current)
    return if active_applications.empty?

    flash[:alert] = {
      title: "Application already registered",
      message: "You have already made an application for #{course.name}",
    }

    redirect_to application_path(active_applications.last.ecf_id)
  end

  def course
    @course ||= Course.reception
  end

  def check_end_of_journey
    return unless @form.valid? && @form.last_step?

    @wizard.save!
    flash[:notice] = {
      title: "Registration successfully submitted",
      message: "Check the details of your registration and find out more about applying with your provider",
    }
    redirect_to application_path(current_user.applications.last.ecf_id)
  end

  def registration_closed
    return if request.path == registration_wizard_show_path(:closed)

    if Feature.registration_closed?(current_user)
      if params[:step] == "start"
        redirect_to registration_closed_path
      else
        redirect_to registration_wizard_show_path(:closed)
      end
    end
  end

  def store
    session["registration_store"] ||= {}
  end

  def wizard_params
    return {} if Feature.registration_closed?(current_user)

    params.fetch(:registration_wizard, {}).permit(RegistrationWizard.permitted_params_for_step(params[:step].underscore))
  end
end
