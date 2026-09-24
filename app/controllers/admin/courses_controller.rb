module Admin
  class CoursesController < AdminController
    include Cohortable

    before_action :set_course, only: %i[edit update]
    before_action :require_super_admin, only: %i[edit update]

    def index
      @pagy, @resources = pagy(resources)
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to admin_courses_path, flash: { success: "Course updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def set_course
      @course = Course.find(params[:id])
    end

    def default_academic_year_actions
      %i[index]
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
