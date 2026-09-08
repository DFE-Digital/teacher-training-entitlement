module Admin
  class CoursesController < AdminController
    include Cohortable

    before_action :set_course, only: %i[edit update]
    before_action :require_super_admin, only: %i[edit update]
    before_action :redirect_to_academic_year, only: %i[show]
    before_action :set_course_cohort, only: %i[show]

    def index
      @pagy, @resources = pagy(resources)
    end

    def show
      @course = @course_cohort.course
      @cohort = @course_cohort.cohort
      @delivery_partner_counts = DeliveryPartnership
      .where(course_cohort: @course_cohort, lead_provider_id: @course_cohort.lead_provider_ids)
      .group(:lead_provider_id)
      .count
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to admin_course_path(@course), flash: { success: "Course updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def set_course
      @course = Course.find(params[:id])
    end

    def default_academic_year_actions
      %i[index show]
    end

    def redirect_to_academic_year
      redirect_to academic_year_admin_courses_path(academic_year: @current_academic_year) if @current_academic_year
    end

    def set_course_cohort
      @course_cohort = CourseCohort
                         .includes(:course, :cohort, course_cohort_providers: :lead_provider)
                         .find_by(course_id: params[:id], cohort_id: params[:cohort_id])

      redirect_to admin_courses_path unless @course_cohort
    end

    def course_params
      params.require(:course).permit(:name, :description)
    end

    def resources
      scope = Course
                .includes(:applications, course_cohorts: :cohort)
                .order(name: :asc)
      scope.merge!(Course.where(course_cohorts: { cohort: @current_cohort })) if @current_cohort
      scope.merge!(Course.where(course_cohorts: { academic_year: @current_academic_year })) if @current_academic_year
      scope
    end
  end
end
