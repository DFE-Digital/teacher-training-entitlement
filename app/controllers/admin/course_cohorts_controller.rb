class Admin::CourseCohortsController < AdminController
  include Admin::Cohortable

  before_action :require_super_admin, only: %i[new create]
  before_action :course_cohort, only: :show

  def index
    @resources = Course
                   .includes(:applications, course_cohorts: :cohort)
                   .order(name: :asc)
    @resources.merge!(Course.where(course_cohorts: { cohort: @current_cohort })) if @current_cohort
    @resources.merge!(Course.where(course_cohorts: { academic_year: @current_academic_year })) if @current_academic_year
  end

  def show
    @delivery_partner_counts = DeliveryPartnership
      .where(course_cohort: @course_cohort, lead_provider_id: @course_cohort.lead_provider_ids)
      .group(:lead_provider_id)
      .count
    @contract_years = @course_cohort.course.contract_years.generic.includes(:lead_provider)
    @contract_financials = @course_cohort.course.contract_years.year(@course_cohort.academic_year).includes(:lead_provider)
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
      redirect_to cohort_admin_course_cohort_path(@course, service.course_cohort.cohort)
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
    attrs = {
      course_id: params[:id],
      cohort_id: params[:cohort_id],
      academic_year: params[:academic_year],
    }.compact

    @course_cohort ||= CourseCohort.includes(:course, :milestones, course_cohort_providers: :lead_provider).find_by!(attrs)
  end
end
