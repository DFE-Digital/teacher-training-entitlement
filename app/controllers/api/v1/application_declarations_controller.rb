module API
  module V1
    class ApplicationDeclarationsController < ApplicationsController
      def started
        service = Declarations::Create.new(application: updateable_application,
                                           **declaration_permitted_params(:started))
        call_and_render(service:)
      end

      def completed
        service = Declarations::Create.new(application: updateable_application,
                                           **declaration_permitted_params(:completed))
        call_and_render(service:)
      end

    private

      def call_and_render(service:)
        call_application_service_and_render(service:) do
          DeclarationSerializer.render(service.declaration, view: :v1, root: "data")
        end
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
