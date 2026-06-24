# frozen_string_literal: true

module Admin
  module Applications
    class LateStartedDeclarationsController < AdminController
      def index
        applications = ::Applications::ApplicationsWithLateStartedDeclarations.new(
          cohort: filters.current_cohort,
          course: filters.current_course,
          lead_provider: filters.current_lead_provider,
          status: filters.current_status,
        ).call

        respond_to do |format|
          format.html { @pagy, @applications = pagy(applications) }
          format.csv do
            send_data(
              ::Applications::LateDeclarationsCsv.new(applications:, expected_by: :training_starts_at).call,
              filename: "late_started_declarations.csv",
              type: "text/csv; charset=utf-8",
            )
          end
        end
      end

    private

      def filters
        @filters ||= LateDeclarationsFiltersComponent.new(
          report_path: ->(params = {}) { admin_applications_late_started_declarations_path(params) },
          query_parameters: request.query_parameters,
        )
      end
    end
  end
end
