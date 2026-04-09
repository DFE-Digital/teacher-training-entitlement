module API
  module V1
    class ApplicationsController < BaseController
      include Pagination
      include FilterByDate
      include FilterByParticipantIds
      include ApplicationServiceCallable

      def index
        applications = applications_query.applications
        render json: to_json(paginate(applications))
      end

      def show
        render json: to_json(application)
      end

      def accept
        service = Applications::Accept.new(application:, funded_place:)
        call_and_render(service:)
      end

      def reject
        service = Applications::Reject.new(
          application:,
          reason_for_rejection: Application.reason_for_rejections[:rejected_by_provider],
        )
        call_and_render(service:)
      end

      def defer
        service = Applications::Defer.new(application:, reason:)
        call_and_render(service:)
      end

      def resume
        service = Applications::Resume.new(application:, course_cohort:)
        call_and_render(service:)
      end

      def withdraw
        service = Applications::Withdraw.new(application:, reason:)
        call_and_render(service:)
      end

      def change_funded_place
        service = Applications::ChangeFundedPlace.new(application:, funded_place:)
        call_and_render(service:)
      end

      def change_schedule
        service = Applications::ChangeSchedule.new(application:, course_cohort:)
        call_and_render(service:)
      end

    protected

      def render_errors(service:)
        status = application.superceded_status? ? :forbidden : :unprocessable_content
        render json: API::Errors::Response.from(service), status:
      end

      def application
        @application ||= current_lead_provider
                          .applications
                          .includes(
                            :user,
                            :institution,
                            course_cohort: %i[course cohort schedule],
                          ).find_by!(ecf_id:)
      end

      def filter_params
        params.permit(:sort, filter: %i[cohort updated_since participant_id status course])
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, view: :v1, root: "data")
      end

      def applications_query
        conditions = {
          cohort_start_years: filter_params.dig(:filter, :cohort),
          participant_ids:, # from FilterableByParticipants
          updated_since:, # from FilterableByDate
          status: filter_params.dig(:filter, :status),
          course_identifier: filter_params.dig(:filter, :course),
          sort: filter_params[:sort],
          lead_provider: current_lead_provider,
        }

        Applications::Query.new(**conditions.compact)
      end

      def ecf_id
        params[:ecf_id]
      end

      def call_and_render(service:)
        call_application_service_and_render(service:, application:) do
          to_json(application)
        end
      end

    private

      def application_action_params
        @application_action_params ||= params
          .require(:data)
          .require(:attributes)
          .permit(:funded_place, :reason, :schedule_id)
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def reason
        application_action_params[:reason]
      end

      def funded_place
        application_action_params[:funded_place]
      end

      def course_cohort
        @course_cohort ||= begin
          course_cohort_ecf_id = application_action_params[:schedule_id]
          current_lead_provider.course_cohorts.find_by(ecf_id: course_cohort_ecf_id)
        end
      end
    end
  end
end
