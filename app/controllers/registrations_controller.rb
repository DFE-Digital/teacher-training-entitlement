class RegistrationsController < PublicPagesController
  helper_method :current_step, :wizard

  before_action :registration_closed
  before_action :redirect_to_start_if_signed_out
  before_action :redirect_to_closed_if_no_course_cohort, only: :show
  before_action :check_allowed_to_apply

  def show
    if params[:step_slug].blank?
      redirect_to step_registration_path(params[:journey_slug], current_step.slug) and return
    end

    wizard.execute_services(execute_point: :before_show)
  end

  def update
    unless wizard.save_current_step
      render :show and return
    end

    wizard.execute_services(execute_point: :after_update)

    next_step = wizard.next_step
    next_path = step_registration_path(params[:journey_slug], next_step.to_s.dasherize) if next_step
    redirect_to current_step.redirect_target || next_path || root_path
  end

  def development_login
    return unless Rails.env.development? || Rails.env.review?

    user = User.find_by!(email: params[:user_email])
    session["user_id"] = user.id
    sign_in user

    redirect_to step_registration_path(params[:journey_slug], params[:step])
  end

private

  def redirect_to_start_if_signed_out
    return if current_user.present?
    return if current_step.slug.to_s.in?(%w[start closed])

    redirect_to root_path
  end

  def redirect_to_closed_if_no_course_cohort
    # TODO: No longer needed?  return unless current_step.slug.to_s == "course-start-date"
    return if CourseCohort.registerable.exists?

    redirect_to registration_closed_path
  end

  def registration_closed
    return unless Feature.registration_closed?(current_user)

    redirect_to registration_closed_path
  end

  def check_allowed_to_apply
    return unless current_user
    # TODO: No longer needed? return if current_step.slug.to_s.in?(%w[registration-submitted share-provider])
    return if current_user.allowed_to_apply?

    application = current_user.applications.last
    flash[:alert] = {
      title: "Application already registered",
      message: "You have already made an application for #{application.course.name}",
    }

    redirect_to application_path(application.ecf_id)
  end

  def wizard
    @wizard ||= begin
      step_slug = params[:step_slug]
      step_id = step_slug&.underscore&.to_sym
      step_params = if step_id
                      raw_params = params[step_slug]
                      raw_params = raw_params.to_unsafe_h if raw_params.respond_to?(:to_unsafe_h)
                      { step_id => raw_params || {} }
                    else
                      {}
                    end

      wizard_options = {
        session:,
        current_step: step_id,
        current_step_params: step_params,
        current_user:,
      }

      wizard_options.merge!(course: Course.find_by!(identifier: journey_slug)) unless journey_slug == COURSE_SELECTION_SLUG
      raise ActiveRecord::RecordNotFound, "Registration journey #{journey_slug} not found" unless WIZARD_COURSE_MAP[journey_slug]

      WIZARD_COURSE_MAP[journey_slug].new(**wizard_options)
    end
  end

  def current_step
    wizard.current_step
  end

  def journey_slug
    @journey_slug ||= params[:journey_slug]
  end

  COURSE_SELECTION_SLUG = "course-selection".freeze
  WIZARD_COURSE_MAP = {
    Course::TTE_EARLY_YEARS => Registrations::Journeys::ExcellenceInReceptionWizard,
    Course::SEND_INCLUSIVE_TEACHERS => Registrations::Journeys::SendInclusivePracticeWizard,
    Course::SEND_INCLUSIVE_LEADERS => Registrations::Journeys::SendInclusivePracticeWizard,
    COURSE_SELECTION_SLUG => Registrations::Journeys::CourseSelectionWizard,
    Course::COURSE_ONE => Registrations::Journeys::Spikes::CourseOneWizard,
    Course::COURSE_TWO => Registrations::Journeys::Spikes::CourseTwoWizard,
  }.freeze
end
