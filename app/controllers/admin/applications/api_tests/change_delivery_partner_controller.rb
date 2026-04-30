module Admin
  module Applications
    module APITests
      class ChangeDeliveryPartnerController < APITestsController
        before_action :set_delivery_partners, :set_declarations

        def create
          @response = ::APITests::ChangeDeliveryPartner.new(
            declaration:,
            delivery_partner:,
            secondary_delivery_partner:,
          ).call
        end

      private

        def set_declarations
          @declarations = @application.declarations
        end

        def set_delivery_partners
          @delivery_partners = @application.lead_provider.delivery_partners.order(created_at: :desc)
        end

        def declaration
          Declaration.find(form_params[:declaration_id])
        end

        def delivery_partner
          DeliveryPartner.find(form_params[:delivery_partner_id])
        end

        def secondary_delivery_partner
          return nil if form_params[:secondary_delivery_partner_id].blank?

          DeliveryPartner.find(form_params[:secondary_delivery_partner_id])
        end

        def form_params
          params.require(:form).permit(:delivery_partner_id, :secondary_delivery_partner_id, :declaration_id)
        end
      end
    end
  end
end
