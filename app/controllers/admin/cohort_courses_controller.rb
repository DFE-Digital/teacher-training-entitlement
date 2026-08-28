class Admin::CohortCoursesController < AdminController
  before_action :ensure_super_admin, except: :show
  before_action :course_cohort, only: :show

  def show
    @cohorts = Cohort.where(id: @course.course_cohorts.select(:cohort_id)).order_by_latest
    @delivery_partner_counts = DeliveryPartnership
      .where(course_cohort: @course_cohort, lead_provider_id: @course_cohort.lead_provider_ids)
      .group(:lead_provider_id)
      .count
  end

  def new
    @course_cohort = cohort.course_cohorts.new
    load_form_options
  end

  def create
    service = CourseCohorts::Create.new(course_cohort_params)
    service.call
    if service.errors.blank?
      @course_cohort = service.course_cohort
      flash[:success] = "Course added to cohort"
      redirect_to admin_cohort_course_path(cohort, @course_cohort.course)
    else
      @course_cohort = service.course_cohort || cohort.course_cohorts.new
      load_form_options
      render :new, status: :unprocessable_content
    end
  end

private

  def course_cohort_params
    params.require(:course_cohort)
      .permit(:course_id, :academic_year, :training_starts_at, :training_ends_at, lead_providers: {})
      .merge(cohort:)
  end

  def course_cohort
    @course_cohort ||= cohort.course_cohorts.includes(:course, :lead_providers, :milestones).find_by!(course_id: params[:id]).tap do |course_cohort|
      @course = course_cohort.course
    end
  end

  def cohort
    @cohort ||= Cohort.find(params[:cohort_id])
  end

  def load_form_options
    @courses = Course.where.not(id: cohort.course_cohorts.select(:course_id)).order(:name)
    @lead_providers = LeadProvider.all
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to change cohort courses"
      redirect_to admin_cohort_path(cohort)
    end
  end
end
