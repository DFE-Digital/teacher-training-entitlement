module Admin
  class CoursesController < AdminController
    include Cohortable
    before_action :require_super_admin, only: %i[edit update]

    def index
      @pagy, @resources = pagy(resources)
    end

    def show
      @course = Course.find(params[:id])
    end

    def edit
      @course = Course.find(params[:id])
    end

    def update
      @course = Course.find(params[:id])

      if @course.update(course_params)
        redirect_to admin_course_path(@course), flash: { success: "Course updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def course_params
      params.require(:course).permit(:name, :description)
    end

    def resources
      scope = Course
                .includes(:course_cohorts, :applications)
                .order(name: :asc)
      scope.merge!(Course.where(course_cohorts: { cohort: @current_cohort })) if @current_cohort
      scope
    end
  end
end
