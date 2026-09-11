class Admin::CohortCoursesController < AdminController
  before_action :ensure_super_admin, except: :show
  before_action :course_cohort, only: :show

  def show
    @course_cohorts = @course.course_cohorts.includes(:cohort).joins(:cohort).order("cohorts.registration_starts_at DESC")
    @delivery_partner_counts = DeliveryPartnership
      .where(course_cohort: @course_cohort, lead_provider_id: @course_cohort.lead_provider_ids)
      .group(:lead_provider_id)
      .count
    @contract_years = @course.contract_years.generic.includes(:lead_provider)
    @contract_financials = @course.contract_years.year(@course_cohort.academic_year).includes(:lead_provider)
    if @contract_financials.blank?
      @contract_financials = @contract_years
    end
  end

  def new
    @form = CourseCohorts::SetupForm.new(cohort:, course_id: params[:course_id])
  end

  def create
    @form = CourseCohorts::SetupForm.new(form_params)
    service = CourseCohorts::Create.new(
      cohort:,
      course: @form.selected_course,
      training_dates: @form.training_dates,
    )

    if @form.valid? && service.valid?
      service.call
      flash[:success] = "Course added to cohort"
      redirect_to admin_cohort_course_path(cohort, service.course)
    else
      @form.add_service_errors(service.errors)
      render :new, status: :unprocessable_content
    end
  end

private

  def form_params
    params.require(:course_cohorts_setup_form)
      .permit(:course_id, :academic_year, :training_starts_at, :training_ends_at)
      .merge(cohort:)
  end

  def course_cohort
    @course_cohort ||= cohort.course_cohorts.includes(:course, :milestones, course_cohort_providers: :lead_provider).find_by!(course_id: params[:id]).tap do |course_cohort|
      @course = course_cohort.course
    end
  end

  def cohort
    @cohort ||= Cohort.find(params[:cohort_id])
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to change cohort courses"
      redirect_to admin_cohort_path(cohort)
    end
  end
end
