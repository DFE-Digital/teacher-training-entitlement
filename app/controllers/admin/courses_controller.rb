module Admin
  class CoursesController < AdminController
    include Cohortable

    def index
      @pagy, @resources = pagy(resources)
    end

    def show
      @course = Course.find(params[:id])
      @course_cohorts = @course.course_cohorts
                               .includes(:cohort, :schedule, course_cohort_providers: :lead_provider)
                               .sort_by { |course_cohort| course_cohort.cohort.start_year }
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
