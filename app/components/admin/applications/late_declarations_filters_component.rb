module Admin
  module Applications
    class LateDeclarationsFiltersComponent < BaseComponent
      def initialize(report_path:, query_parameters:)
        @report_path = report_path
        @query_parameters = query_parameters
      end

      def filter_sections
        [
          section("Cohorts", "cohort_id", cohorts, current_cohort, :description),
          section("Courses", "course_id", courses, current_course, :name),
          section("Lead providers", "lead_provider_id", lead_providers, current_lead_provider, :name),
          section("Statuses", "status", statuses, current_status, :humanize),
        ]
      end

      def filter_path(key, value)
        report_path.call(filter_params.merge(key => value))
      end

      def clear_filter_path(key)
        report_path.call(filter_params.except(key))
      end

      def selected_filter?(current_value, value)
        current_value.to_s == value.to_s
      end

      def filter_params
        query_parameters.except("page")
      end

      def current_cohort
        return if query_parameters["cohort_id"].blank?

        @current_cohort ||= cohorts.find(query_parameters["cohort_id"])
      end

      def current_course
        return if query_parameters["course_id"].blank?

        @current_course ||= courses.find(query_parameters["course_id"])
      end

      def current_lead_provider
        return if query_parameters["lead_provider_id"].blank?

        @current_lead_provider ||= lead_providers.find(query_parameters["lead_provider_id"])
      end

      def current_status
        @current_status ||= query_parameters["status"].presence
      end

    private

      attr_reader :report_path, :query_parameters

      def cohorts
        @cohorts ||= Cohort.order_by_latest
      end

      def courses
        @courses ||= Course.order(:name)
      end

      def lead_providers
        @lead_providers ||= LeadProvider.order(:name)
      end

      def statuses
        @statuses ||= Application::STATUSES - [Application::WITHDRAWN, Application::REJECTED]
      end

      def section(title, key, values, current_value, label_method)
        {
          title:,
          key:,
          values:,
          current_value:,
          label_method:,
        }
      end
    end
  end
end
