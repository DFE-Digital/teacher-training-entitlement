class Admin::CourseCohortsController < AdminController
  before_action :ensure_super_admin, except: :show
  before_action :course, only: :show
  before_action :course_cohort, only: :show

  def show
    @cohort = course_cohort.cohort
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
    @cohort = Cohort.find(params[:cohort_id])
    @form = CourseCohorts::SetupForm.new(cohort: @cohort)
  end

  def create
    @form = CourseCohorts::SetupForm.new(form_params)
    @course = @form.selected_course
    @cohort = @form.selected_cohort

    service = CourseCohorts::Create.new(
      cohort: @cohort,
      course: @course,
      training_starts_at: @form.training_starts_at,
    )

    if @form.valid? && service.valid?
      service.call
      flash[:success] = "Course added to registration period"
      redirect_to admin_course_cohort_path(@course, service.course_cohort.cohort)
    else
      @form.add_service_errors(service.errors)
      render :new, status: :unprocessable_content
    end
  end

private

  def form_params
    params.require(:course_cohorts_setup_form)
      .permit(:course_id, :cohort_id, :academic_year, :training_starts_at)
      .merge(form_context)
  end

  def form_context
    { cohort: Cohort.find(params[:cohort_id]) }
  end

  def course_cohort
    @course_cohort ||= course.course_cohorts.includes(:course, :milestones, course_cohort_providers: :lead_provider).find_by!(cohort_id: params[:id])
  end

  def cohort
    @cohort ||= course_cohort.cohort
  end

  def course
    @course ||= Course.find(params[:course_id])
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin"
      redirect_to admin_courses_path
    end
  end
end
