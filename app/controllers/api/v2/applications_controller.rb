module API
  module V2
    class ApplicationsController < BaseController
      include Includes
      include Filters
      include Sorting
      include Pagination

      allowed_includes "teacher", "contract", "outcome", "surveys", "expected_declarations"
      allowed_filters :course, :term, :academic_year, :funding_eligible, :funding_uplift,
                      :teacher_trn, :teacher_ecf_id, :email, :updated_since
      allowed_sorts(*Applications::Query::SORT_FIELDS, default: "updated_at")

      # Validate the include list (and, for the index, sort and page) before any query or
      # association traversal. Show rejects the list-only parameters.
      single_resource_actions :show
      before_action :requested_includes
      before_action :requested_sort, :page_size, only: :index

      def index
        query = applications_query
        assignments = paginate(query.application_lead_providers, keys: query.sort_keys)

        render_document(
          ApplicationSerializer.new(
            presenters(assignments),
            include: requested_includes,
            links: pagination_links,
          ).serializable_hash,
        )
      end

      def show
        assignment = applications_query.application_lead_provider(ecf_id: params[:id])

        render_document(
          ApplicationSerializer.new(presenters([assignment]).first, include: requested_includes).serializable_hash,
        )
      end

    private

      def applications_query
        return Applications::Query.new(lead_provider: current_lead_provider) unless action_name == "index"

        Applications::Query.new(lead_provider: current_lead_provider, filters:, sort: requested_sort)
      end

      def presenters(assignments)
        outcomes = Applications::OutcomesQuery.new(
          lead_provider: current_lead_provider,
          application_ids: assignments.map(&:application_id),
        ).call

        assignments.map { |assignment| ApplicationPresenter.new(assignment, outcome: outcomes[assignment.application_id]) }
      end

      def filters
        {
          course: list_filter(:course),
          term: list_filter(:term, allowed: CourseCohort::TERM_IDENTIFIERS.keys.map(&:to_s)),
          academic_year: list_filter(:academic_year, format: /\A\d{4}\z/),
          funding_eligible: boolean_filter(:funding_eligible),
          funding_uplift: boolean_filter(:funding_uplift),
          teacher_trn: list_filter(:teacher_trn, format: TRN_FORMAT),
          teacher_ecf_id: list_filter(:teacher_ecf_id, format: UUID_FORMAT),
          email: list_filter(:email, format: EMAIL_FORMAT),
          updated_since: time_filter(:updated_since),
        }
      end
    end
  end
end
