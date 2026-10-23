module Admin
  module Applications
    module APITests
      class RetainedDeclarationsController < APITestsController
        before_action :set_delivery_partners
        before_action :set_declaration_type

        def create
          @response = ::APITests::RetainedDeclaration.new(
            application: @application,
            declaration_type: @declaration_type,
            delivery_partner: DeliveryPartner.find(form_params[:delivery_partner_id]),
          ).call
        end

      private

        def set_delivery_partners
          @delivery_partners = @application.lead_provider.delivery_partners.order(created_at: :desc)
        end

        def set_declaration_type
          @declaration_type = params[:declaration_type]
          @form_url = if @declaration_type == Milestone::RETAINED_1
                        admin_applications_api_tests_retained_1_declarations_path(@application)
                      else
                        admin_applications_api_tests_retained_2_declarations_path(@application)
                      end
        end

        def form_params
          params.require(:form).permit(:delivery_partner_id)
        end
      end
    end
  end
end
