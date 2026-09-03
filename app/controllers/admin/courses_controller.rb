module Admin
  class CoursesController < AdminController
    include Cohortable

    before_action :set_course, only: %i[show edit update]
    before_action :require_super_admin, only: %i[edit update]

    def index
      @pagy, @resources = pagy(resources)
    end

    def show
      @course_cohorts = @course.course_cohorts.includes(:cohort).joins(:cohort).order("cohorts.registration_starts_at DESC")
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

    def course_params
      params.require(:course).permit(:name, :description)
    end

    def resources
      scope = Course
                .includes(:applications, course_cohorts: :cohort)
                .order(name: :asc)
      scope.merge!(Course.where(course_cohorts: { cohort: @current_cohort })) if @current_cohort
      scope
    end
  end
end
