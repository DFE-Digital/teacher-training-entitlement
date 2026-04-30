module APITests
  class ChangeDeliveryPartner
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(declaration: nil, delivery_partner: nil, secondary_delivery_partner: nil)
      @declaration = declaration
      @delivery_partner = delivery_partner
      @secondary_delivery_partner = secondary_delivery_partner
    end

    def call
      if declaration.nil?
        raise "[ChangeDeliveryPartner] Could not find a declaration"
      end

      body = {
        data:
        {
          attributes: {
            delivery_partner_id:,
            secondary_delivery_partner_id:,
          },
        },
      }.to_json

      path = change_delivery_partner_api_v1_declaration_path(declaration.ecf_id)

      api_put(lead_provider:, path:, body:)
    end

  private

    def secondary_delivery_partner_id
      return @secondary_delivery_partner if @secondary_delivery_partner
      return nil unless lead_provider.delivery_partners.many?

      lead_provider.delivery_partners.last.ecf_id
    end

    def delivery_partner_id
      @delivery_partner&.ecf_id || lead_provider.delivery_partners.first.ecf_id
    end

    def lead_provider
      declaration.lead_provider
    end

    def declaration
      @declaration ||= Declaration.last
    end
  end
end
