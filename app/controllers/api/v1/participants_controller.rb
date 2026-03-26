module API
  module V1
    class ParticipantsController < BaseController
      include Pagination
      include FilterByDate

      before_action :check_participant_id_change, only: :show

      def index
        conditions = { updated_since:, status:, from_participant_id:, sort: }
        participants = participants_query(conditions:).participants

        render json: to_json(paginate(participants))
      end

      def show
        render json: to_json(participant)
      end

    private

      def status
        participant_params.dig(:filter, :status)
      end

      def from_participant_id
        participant_params.dig(:filter, :from_participant_id)
      end

      def participants_query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        ::Participants::Query.new(**conditions.compact)
      end

      def sort
        participant_params[:sort]
      end

      def participant_params
        params.permit(:ecf_id, :sort, filter: %i[status from_participant_id])
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, view: :v1, root: "data", lead_provider: current_lead_provider)
      end

      def participant
        participants_query.participant(ecf_id: participant_params[:ecf_id])
      end
    end
  end
end
