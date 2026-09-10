module API
  module V1
    class CourseCohortsController < BaseController
      include Pagination

      def index
        render json: to_json(paginate(course_cohorts_query.course_cohorts))
      end

    private

      def course_cohorts_query
        conditions = {
          lead_provider: current_lead_provider,
          academic_years: params.dig(:filter, :cohort),
          course_identifier: params.dig(:filter, :course),
          sort: params[:sort],
        }

        CourseCohorts::Query.new(**conditions.compact)
      end

      def to_json(obj)
        CourseCohortSerializer.render(obj, view: :v1, root: "data")
      end
    end
  end
end
