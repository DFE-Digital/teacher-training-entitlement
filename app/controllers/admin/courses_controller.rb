module Admin
  class CoursesController < AdminController
    include Cohortable

    def index
      @pagy, @resources = pagy(resources)
    end

    def show
      @course = Course.find(params[:id])
    end

  private

    def resources
      scope = Course
                .includes(:course_cohorts, :applications)
                .order(name: :asc)
      scope.merge!(Course.where(course_cohorts: { cohort: @current_cohort })) if @current_cohort
      scope
    end
  end
end
