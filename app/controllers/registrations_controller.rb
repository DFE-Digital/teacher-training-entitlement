class RegistrationsController < PublicPagesController
  helper_method :current_step, :router

  before_action :registration_closed
  before_action :redirect_to_start_if_signed_out
  before_action :redirect_to_closed_if_no_course_cohort, only: :show
  before_action :check_allowed_to_apply

  def show
    redirect_to root_path and return if router.should_exit?

    Registrations::StepServiceExecutor.new(
      router_step: current_step,
      execute_point: :before_show,
    ).call
  end

  def update
    unless current_step.valid?
      render :show and return
    end

    current_step.store_answer!
    Registrations::StepServiceExecutor.new(
      router_step: current_step,
      execute_point: :after_update,
    ).call

    redirect_to current_step.redirect_target || step_registration_path(params[:journey_slug], router.next_step_slug)
  end

  def development_login
    return unless Rails.env.development? || Rails.env.review?

    user = User.find_by!(email: params[:user_email])
    session["user_id"] = user.id
    sign_in user

    redirect_to step_registration_path(params[:journey_slug], "course-start-date")
  end

private

  def redirect_to_start_if_signed_out
    return if current_user.present?
    return if current_step.slug.to_s.in?(%w[start closed])

    redirect_to root_path
  end

  def redirect_to_closed_if_no_course_cohort
    return unless current_step.slug.to_s == "course-start-date"
    return if CourseCohort.registerable.exists?

    redirect_to registration_closed_path
  end

  def registration_closed
    return unless Feature.registration_closed?(current_user)

    redirect_to registration_closed_path
  end

  def check_allowed_to_apply
    return unless current_user
    return if current_step.slug.to_s.in?(%w[registration-submitted share-provider])
    return if current_user.allowed_to_apply?

    application = current_user.applications.last
    flash[:alert] = {
      title: "Application already registered",
      message: "You have already made an application for #{application.course.name}",
    }

    redirect_to application_path(application.ecf_id)
  end

  def router
    @router ||= Registrations::Router.new(
      params:, session:,
      current_user:
    )
  end

  def current_step
    router.router_step
  end
end
