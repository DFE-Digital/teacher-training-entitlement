class RegistrationWizardController < PublicPagesController
  before_action :registration_closed
  before_action :set_wizard
  before_action :set_form
  before_action :check_duplicate_applications, only: %i[update]
  before_action :ensure_can_render_step, only: :show

  rescue_from FundingEligibility::MissingMandatoryInstitution, with: :redirect_to_institution_picker
  rescue_from RegistrationWizard::RemovedStep, with: :redirect_to_course_start_date

  helper_method :course

  def show
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    @wizard.before_render

    render @wizard.current_step

    @wizard.after_render
  rescue ActionView::Template::Error => e
    if e.cause.instance_of?(Questionnaires::IneligibleForFunding::UnexpectedEligibilityStatusCode)
      redirect_to_course_start_date
    else
      raise e
    end
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

  def ensure_can_render_step
    return redirect_to root_path unless @form.requirements_met?
    return redirect_to registration_wizard_show_path(@wizard.next_step_path) if @wizard.skip_step?

    redirect_to root_path if store.except("current_user_id").blank? &&
      !params[:step].in?(RegistrationWizard::VALID_BLANK_STEPS)
  end

  def redirect_to_course_start_date
    redirect_to registration_wizard_show_path("course-start-date")
  end

  def redirect_to_institution_picker
    query_store = RegistrationQueryStore.new(store:)

    if query_store.works_in_school?
      flash[:error] = "Your application requires details of your school."
      redirect_to registration_wizard_show_path("choose-school")
    elsif query_store.kind_of_nursery_private?
      flash[:error] = "Your application requires details of your nursery."
      redirect_to registration_wizard_show_path("have-ofsted-urn")
    elsif query_store.works_in_childcare?
      flash[:error] = "Your application requires details of your early years setting."
      redirect_to registration_wizard_show_path("choose-childcare-provider")
    else
      raise "Could not resolve institution picker"
    end
  end

  def set_wizard
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore, store:, params: wizard_params, request:, current_user:)
  end

  def set_form
    @form = @wizard.form
  end

  def check_duplicate_applications
    return unless @wizard.current_step.to_s == "course_start_date"

    active_applications = current_user.active_applications_for(course:, cohort: Cohort.current)
    return if active_applications.empty?

    flash[:alert] = {
      title: "Application already registered",
      message: "You have already made an application for #{course.name}",
    }

    redirect_to application_path(active_applications.last.ecf_id)
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

  def course
    @course ||= Course.reception
  end
end
