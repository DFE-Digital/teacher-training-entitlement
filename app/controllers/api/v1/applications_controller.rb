module API
  module V1
    class ApplicationsController < BaseController
      include Pagination
      include FilterByDate
      include FilterByParticipantIds

      def index
        conditions = { cohort_start_years:, participant_ids:, updated_since:, status:, course_identifier:, sort: }
        applications = applications_query(conditions:).applications

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
          reason_for_rejection: rejection_reason,
        )

        if service.reject
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

      def defer
        service = Applications::Defer.new(application:, reason: application_action_params[:reason])
        service.call

        if service.errors.blank?
          render json: to_json(application.reload)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def resume
        service = Applications::Resume.new(application:)
        service.call

        if service.errors.blank?
          render json: to_json(application.reload)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def withdraw
        service = Applications::Withdraw.new(application:, reason: application_action_params[:reason])
        service.call

        if service.errors.blank?
          render json: to_json(application.reload)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def change_schedule
        schedule = Schedule.find_by!(ecf_id: application_action_params[:schedule_id])
        service = Participants::ChangeSchedule.new_filtering_attributes(
          participant_id: application.user.ecf_id,
          course_identifier: application.course.identifier,
          schedule_identifier: schedule.identifier,
          cohort: schedule.cohort.start_year,
          lead_provider: current_lead_provider,
        )

        if service.change_schedule
          render json: to_json(application.reload)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def declaration_started
        service = Declarations::Create.new(declaration_params_for_application(declaration_type: "started"))

        if service.create_declaration
          render json: declaration_to_json(service.declaration)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def declaration_completed
        service = Declarations::Create.new(declaration_params_for_application(declaration_type: "completed"))

        if service.create_declaration
          render json: declaration_to_json(service.declaration)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

    private

      def applications_query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        Applications::Query.new(**conditions.compact)
      end

      def application
        @application ||= applications_query.application(ecf_id: application_params[:ecf_id])
      end

      def cohort_start_years
        application_params.dig(:filter, :cohort)
      end

      def application_params
        params.permit(:ecf_id, :sort, filter: %i[cohort updated_since participant_id status course])
      end

      def sort
        application_params[:sort]
      end

      def status
        application_params.dig(:filter, :status)
      end

      def course_identifier
        application_params.dig(:filter, :course)
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, view: :v1, root: "data")
      end

      def declaration_to_json(obj)
        DeclarationSerializer.render(obj, view: :v1, root: "data")
      end

      def accept_permitted_params
        parameters = params
          .fetch(:data)
          .permit(:type, attributes: %i[funded_place schedule_identifier])

        return parameters if parameters["attributes"].present?

        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      rescue ActionController::ParameterMissing
        {}
      end

      def application_action_params
        @application_action_params ||= params
          .require(:data)
          .require(:attributes)
          .permit(:reason, :schedule_id)
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def reject_permitted_params
        params
          .fetch(:data, {})
          .permit(:type, attributes: %i[reason])
      rescue ActionController::ParameterMissing
        {}
      end

      def rejection_reason
        reason = reject_permitted_params.dig("attributes", "reason")
        reason.present? ? reason : Application.reason_for_rejections[:rejected_by_provider]
      end

      def funded_place
        accept_permitted_params.dig("attributes", "funded_place")
      end

      def declaration_permitted_params
        params
          .fetch(:data)
          .permit(:type, attributes: %i[declaration_date delivery_partner_id secondary_delivery_partner_id has_passed])
          .fetch(:attributes, {})
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def declaration_params_for_application(declaration_type:)
        declaration_permitted_params.merge(
          lead_provider: current_lead_provider,
          participant_id: application.user.ecf_id,
          course_identifier: application.course.identifier,
          declaration_type:,
        )
      end
    end
  end
end
