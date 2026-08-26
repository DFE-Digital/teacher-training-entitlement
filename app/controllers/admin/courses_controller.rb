module Admin
  class CoursesController < AdminController
    include Cohortable

    before_action :set_course, only: %i[show edit update]
    before_action :require_super_admin, only: %i[new create edit update]

    def index
      @pagy, @resources = pagy(resources)
    end

    def show
      @cohorts = Cohort.where(id: @course.course_cohorts.select(:cohort_id)).order_by_latest
    end

    def new
      @course = Course.new
    end

    def create
      @course = Course.new(course_params.merge(ecf_id: SecureRandom.uuid))

      if @course.save
        redirect_to admin_course_path(@course), flash: { success: "Course created" }
      else
        render :new, status: :unprocessable_content
      end
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
      params.require(:course).permit(:name, :identifier, :description)
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
