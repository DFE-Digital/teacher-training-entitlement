module API
  module V1
    class DeclarationsController < BaseController
      include Pagination
      include FilterByDate

      before_action :ensure_declaration_belongs_to_lead_provider, only: %i[void change_delivery_partner]

      def index
        conditions = { updated_since:, cohort_start_years:, application_id:, declaration_type:, course_identifier: }
        declarations = declarations_query(conditions:).declarations
                         .includes(:delivery_partner, :secondary_delivery_partner)

        render json: to_json(paginate(declarations))
      end

      def show
        render json: to_json(declaration)
      end

      def void
        service = Declarations::VoidStrategy.for(declaration:)

        service.call

        if service.errors.blank?
          render json: to_json(declaration.reload)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def change_delivery_partner
        service = Declarations::ChangeDeliveryPartner.new(declaration:, delivery_partner_id:, secondary_delivery_partner_id:)

        if service.change_delivery_partner
          render json: to_json(service.declaration)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

    private

      def declarations_query(conditions: {})
        conditions.merge!(
          lead_provider: current_lead_provider,
          include_transferred_applications: Feature.lp_transferred_declarations_visibility?,
        )
        Declarations::Query.new(**conditions.compact)
      end

      def declaration
        @declaration ||= declarations_query.declaration(ecf_id: params[:ecf_id])
      end

      def change_delivery_partner_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:delivery_partner_id,
                  :secondary_delivery_partner_id)
          .merge(
            lead_provider: current_lead_provider,
          )
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def cohort_start_years
        params.dig(:filter, :cohort)
      end

      def application_id
        params.dig(:filter, :application_id)
      end

      def declaration_type
        params.dig(:filter, :declaration_type)
      end

      def course_identifier
        params.dig(:filter, :course)
      end

      def to_json(obj)
        DeclarationSerializer.render(obj, view: :v1, root: "data")
      end

      def delivery_partner_id
        change_delivery_partner_params["delivery_partner_id"]
      end

      def secondary_delivery_partner_id
        change_delivery_partner_params["secondary_delivery_partner_id"]
      end

      def ensure_declaration_belongs_to_lead_provider
        return if declaration.lead_provider == current_lead_provider

        errors = [{
          title: "Cannot modify declaration",
          detail: "The declaration cannot be modified because it was created by another lead provider",
        }]

        render json: { errors: }, status: :forbidden
      end
    end
  end
end
