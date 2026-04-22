module API
  module V1
    class ApplicationsController < BaseController
      include Pagination
      include FilterByDate
      include FilterByParticipantIds
      include ServiceCallable

      def index
        applications = applications_query.applications
        render json: ApplicationSerializer.render(paginate(applications), view: :v1, root: "data")
      end

      def show
        render json: to_json(readable_application)
      end

      def accept
        service = Applications::Accept.new(application: updateable_application, funded_place:)
        call_and_render(service:)
      end

      def reject
        service = Applications::Reject.new(
          application: updateable_application,
          reason_for_rejection: Application.reason_for_rejections[:rejected_by_provider],
        )
        call_and_render(service:)
      end

      def defer
        service = Applications::Defer.new(application: updateable_application, reason:)
        call_and_render(service:)
      end

      def resume
        service = Applications::Resume.new(application: updateable_application, course_cohort:)
        call_and_render(service:)
      end

      def withdraw
        service = Applications::Withdraw.new(application: updateable_application, reason:)
        call_and_render(service:)
      end

      def change_funded_place
        service = Applications::ChangeFundedPlace.new(application: updateable_application, funded_place:)
        call_and_render(service:)
      end

      def change_schedule
        service = Applications::ChangeSchedule.new(application: updateable_application, course_cohort:)
        call_and_render(service:)
      end

    protected

      #
      # Providers can read an application if they were once assigned as provider
      # If they were never assigned, an ActiceRecord::RecordNotFound is raised
      # leading to a 404
      #
      def readable_application
        @readable_application ||= application_lead_provider.application
      end

      #
      # Providers can update an application if they are the active provider
      # If they were never assigned, initiate a 404
      # If they were once assigned, but are no longer, initiate a 403
      #
      def updateable_application
        unless application_lead_provider.current?
          # Lead provider was once assigned to the application
          # but no longer is and so cannot be updated
          raise ForbiddenError
        end

        @updateable_application ||= application_lead_provider.application
      end

      def application_lead_provider
        @application_lead_provider ||=
          current_lead_provider
            .application_lead_providers
            .includes(
              application: [:user,
                            :institution,
                            { course_cohort: %i[course cohort schedule] }],
            ).find_by!(application: { ecf_id: })
      end

      def filter_params
        params.permit(:sort, filter: %i[cohort updated_since participant_id status course])
      end

      def to_json(obj)
        view = application_lead_provider.current? ? :v1 : :v1_reassigned
        ApplicationSerializer.render(obj, view:, root: "data")
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

      def call_and_render(service:)
        call_application_service_and_render(service:) do
          to_json(updateable_application)
        end
      end

    private

      def ecf_id
        params[:ecf_id]
      end

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
