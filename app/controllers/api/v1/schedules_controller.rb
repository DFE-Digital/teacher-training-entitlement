module API
  module V1
    class SchedulesController < BaseController
      include Pagination

      def index
        render json: to_json(paginate(schedules_query.schedules))
      end

    private

      def schedules_query
        conditions = {
          lead_provider: current_lead_provider,
          cohort_start_years: params.dig(:filter, :cohort),
          course_identifier: params.dig(:filter, :course),
          sort: params[:sort],
        }

        Schedules::Query.new(**conditions.compact)
      end

      def to_json(obj)
        ScheduleSerializer.render(obj, view: :v1, root: "data")
      end
    end
  end
end
