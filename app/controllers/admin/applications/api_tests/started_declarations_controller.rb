module Admin
  module Applications
    module APITests
      class StartedDeclarationsController < APITestsController
        before_action :set_delivery_partners

        def create
          @response = ::APITests::StartedDeclaration.new(
            application: @application,
            delivery_partner: DeliveryPartner.find(form_params[:delivery_partner_id]),
          ).call
        end

      private

        def set_delivery_partners
          @delivery_partners = @application.lead_provider.delivery_partners.order(created_at: :desc)
        end

        def form_params
          params.require(:form).permit(:delivery_partner_id)
        end
      end
    end
  end
end
