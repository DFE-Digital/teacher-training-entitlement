module API
  module V1
    class ApplicationsController < BaseController
      include Pagination
      include FilterByDate
      include FilterByParticipantIds
      include ServiceCallable

      def index
        applications = applications_query.applications
        render json: to_json(paginate(applications))
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

      def readable_application
        @readable_application ||= begin
          application = Application
                          .includes(
                            :user,
                            :institution,
                            course_cohort: %i[course cohort schedule],
                          ).find_by!(ecf_id: params[:ecf_id])
          unless application.lead_provider == current_lead_provider || application.readonly_for?(provider: current_lead_provider)
            raise ActiveRecord::RecordNotFound
          end

          application
        end
      end

      def updateable_application
        @updateable_application ||= begin
          application = Application.find_by!(ecf_id: params[:ecf_id])
          return application if application.lead_provider == current_lead_provider
          if application.readonly_for?(provider: current_lead_provider)
            raise ForbiddenError
          else
            raise ActiveRecord::RecordNotFound
          end
        end
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

      def call_and_render(service:)
        call_application_service_and_render(service:) do
          to_json(updateable_application)
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
