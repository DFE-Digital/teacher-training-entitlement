module API
  module V1
    class OutcomesController < BaseController
      include Pagination
      include FilterByDate

      def index
        conditions = { created_since:, application_id: }
        outcomes = outcomes_query(conditions:).participant_outcomes

        render json: to_json(paginate(outcomes))
      end

    private

      def outcomes_query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        ParticipantOutcomes::Query.new(**conditions.compact)
      end

      def to_json(obj)
        ParticipantOutcomeSerializer.render(obj, view: :v1, root: "data")
      end

      def application_id
        params.dig(:filter, :application_id)
      end
    end
  end
end
