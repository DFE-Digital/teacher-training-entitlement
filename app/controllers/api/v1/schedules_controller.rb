module API
  module V1
    class SchedulesController < BaseController
      include Pagination

      def index
        course_cohorts = current_lead_provider
          .course_cohorts
          .includes(:schedule, :course, :cohort)

        render json: to_json(paginate(course_cohorts))
      end

    private

      def to_json(obj)
        ScheduleSerializer.render(obj, view: :v1, root: "data")
      end
    end
  end
end
