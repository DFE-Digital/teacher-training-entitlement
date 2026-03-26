module API
  module V1
    module Participants
      class OutcomesController < BaseController
        include Pagination

        before_action :check_participant_id_change, only: :index

        def index
          conditions = { participant_ids: participant.ecf_id }
          outcomes = outcomes_query(conditions:).participant_outcomes

          render json: to_json(paginate(outcomes))
        end

        def create
          service = ParticipantOutcomes::Create.new(outcome_params)

          if service.create_outcome
            render json: to_json(service.created_outcome)
          else
            render json: API::Errors::Response.from(service), status: :unprocessable_content
          end
        end

      private

        def outcome_params
          params
            .require(:data)
            .require(:attributes)
            .permit(:course_identifier, :state, :completion_date)
            .merge(
              application:,
              lead_provider: current_lead_provider,
              participant_id: participant.ecf_id,
            )
        rescue ActionController::ParameterMissing
          raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
        end

        def participants_query
          ::Participants::Query.new(lead_provider: current_lead_provider)
        end

        def participant
          participants_query.participant(ecf_id: params[:ecf_id])
        end

        def application
          @application ||= participant
            &.applications
            &.accepted
            &.includes(:course)
            &.find_by(lead_provider: current_lead_provider, course: { identifier: course_identifier })
        end

        def outcomes_query(conditions: {})
          conditions.merge!(lead_provider: current_lead_provider)
          ParticipantOutcomes::Query.new(**conditions.compact)
        end

        def to_json(obj)
          ParticipantOutcomeSerializer.render(obj, view: :v1, root: "data")
        end

        def course_identifier
          params.dig(:data, :attributes, :course_identifier)
        end
      end
    end
  end
end
