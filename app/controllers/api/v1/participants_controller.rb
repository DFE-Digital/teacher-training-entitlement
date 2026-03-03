module API
  module V1
    class ParticipantsController < BaseController
      include Pagination
      include FilterByDate

      before_action :check_participant_id_change, only: :show

      def index
        conditions = { updated_since:, training_status:, from_participant_id:, sort: }
        participants = participants_query(conditions:).participants

        render json: to_json(paginate(participants))
      end

      def show
        render json: to_json(participant)
      end

      def resume
        service = ::Applications::Resume.new(application:)
        call_and_render(service:)
      end

      def defer
        service = ::Applications::Defer.new(application:, reason:)

        call_and_render(service:)
      end

      def withdraw
        service = ::Applications::Withdraw.new(application:, reason:)
        call_and_render(service:)
      end

      def change_schedule
        service = ::Participants::ChangeSchedule.new_filtering_attributes(participant_action_params)

        if service.change_schedule
          render json: to_json(service.participant)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

    private

      def call_and_render(service:)
        if application.nil?
          service.errors.add(:base, :application_not_found)
        else
          service.call
        end

        if service.errors.blank?
          render json: to_json(participant)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def course_identifier
        participant_action_params[:course_identifier]
      end

      def reason
        participant_action_params[:reason]
      end

      def training_status
        participant_params.dig(:filter, :training_status)
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
        params.permit(:ecf_id, :sort, filter: %i[training_status from_participant_id])
      end

      def participant_action_params
        @participant_action_params ||= params
          .require(:data)
          .require(:attributes)
          .permit(:course_identifier, :reason, :schedule_identifier, :cohort)
          .merge(
            participant_id: participant.ecf_id,
            lead_provider: current_lead_provider,
          )
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, view: :v1, root: "data", lead_provider: current_lead_provider)
      end

      def participant
        participants_query.participant(ecf_id: participant_params[:ecf_id])
      end

      def application
        @application ||= participant
          &.applications
          &.accepted
          &.includes(:course)
          &.find_by(lead_provider: current_lead_provider, course: { identifier: course_identifier })
      end
    end
  end
end
