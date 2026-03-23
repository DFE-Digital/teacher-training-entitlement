module API
  module V1
    class ApplicationsController < BaseController
      include Pagination
      include FilterByDate
      include FilterByParticipantIds

      def index
        applications = applications_query.applications
        render json: to_json(paginate(applications))
      end

      def show
        render json: to_json(application)
      end

      def accept
        service = Applications::Accept.new(application:, funded_place:)

        if service.accept
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def reject
        service = Applications::Reject.new(
          application:,
          reason_for_rejection: Application.reason_for_rejections[:rejected_by_provider],
        )

        if service.reject
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def defer
        service = Applications::Defer.new(application:, reason:)

        if service.call
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def resume
        service = Applications::Resume.new(application:, course_cohort:)

        if service.call
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def withdraw
        service = Applications::Withdraw.new(application:, reason:)

        if service.call
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def change_funded_place
        service = Applications::ChangeFundedPlace.new(application:, funded_place:)

        if service.change
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def change_schedule
        service = Applications::ChangeSchedule.new(application:, course_cohort:)

        if service.call
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def started_declaration
        service = Declarations::Create.new(application:, **declaration_permitted_params(:started))

        if service.call
          render json: declaration_to_json(service.declaration)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def completed_declaration
        service = Declarations::Create.new(application:, **declaration_permitted_params(:completed))

        if service.call
          render json: declaration_to_json(service.declaration)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

    private

      def application
        @application ||= current_lead_provider
                           .applications
                           .includes(
                             :user,
                             :institution,
                             course_cohort: %i[course cohort schedule],
                           )
                           .find_by!(ecf_id: params[:ecf_id])
      end

      def filter_params
        params.permit(:sort, filter: %i[cohort updated_since participant_id status course])
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
        course_cohort_ecf_id = application_action_params[:schedule_id]
        current_lead_provider.course_cohorts.find_by!(ecf_id: course_cohort_ecf_id)
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, view: :v1, root: "data")
      end

      def declaration_to_json(obj)
        DeclarationSerializer.render(obj, view: :v1, root: "data")
      end

      def declaration_permitted_params(declaration_type)
        params
          .fetch(:data)
          .permit(:type, attributes: %i[declaration_date delivery_partner_id secondary_delivery_partner_id has_passed])
          .fetch(:attributes, {})
          .merge(declaration_type:)
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end
    end
  end
end
