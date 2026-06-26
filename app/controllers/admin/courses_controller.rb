module Admin
  class CoursesController < AdminController
    before_action :set_course, only: %i[show edit update]
    before_action :require_super_admin, only: %i[edit update]

    def index
      @pagy, @resources = pagy(resources)
    end

    def show
      @cohorts = @course.cohorts.order_by_latest
      @cohort_applications_counts = Application.where(cohort: @course.cohorts).group(:cohort_id).count
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
      Course.includes(:cohorts, :applications).order(name: :asc)
    end
  end
end
