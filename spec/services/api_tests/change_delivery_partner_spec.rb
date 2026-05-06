require "rails_helper"

RSpec.describe APITests::ChangeDeliveryPartner, type: :model do
  subject(:service) do
    described_class.new(
      declaration:,
      delivery_partner:,
      secondary_delivery_partner:,
    )
  end

  let(:application) { create(:application, :accepted, lead_provider:, course_cohort:) }
  let(:declaration) { create(:declaration, :started, application:, lead_provider:, course_cohort:, delivery_partner: default_delivery_partner) }
  let(:lead_provider) { create(:lead_provider, delivery_partners: { cohort => [default_delivery_partner, fallback_secondary_delivery_partner] }) }
  let(:course_cohort) { create(:course_cohort, cohort:) }
  let(:cohort) { create(:cohort, :current) }
  let(:default_delivery_partner) { create(:delivery_partner) }
  let(:fallback_secondary_delivery_partner) { create(:delivery_partner) }
  let(:delivery_partner) { create(:delivery_partner) }
  let(:secondary_delivery_partner) { nil }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }

  let(:expected_body) do
    {
      data: {
        attributes: {
          delivery_partner_id: delivery_partner.ecf_id,
          secondary_delivery_partner_id: fallback_secondary_delivery_partner.ecf_id,
        },
      },
    }.to_json
  end

  let(:expected_url) do
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{Rails.application.routes.url_helpers.change_delivery_partner_api_v1_declaration_path(declaration.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:put).and_return(api_response)
  end

  describe "#call" do
    it "sends a change delivery partner request" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:put).with(
        expected_url,
        body: expected_body,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when a delivery partner is not provided" do
      let(:delivery_partner) { nil }

      let(:expected_body) do
        {
          data: {
            attributes: {
              delivery_partner_id: default_delivery_partner.ecf_id,
              secondary_delivery_partner_id: fallback_secondary_delivery_partner.ecf_id,
            },
          },
        }.to_json
      end

      it "uses the lead provider's first delivery partner" do
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when there is only one delivery partner" do
      let(:lead_provider) { create(:lead_provider, delivery_partners: { cohort => default_delivery_partner }) }

      let(:expected_body) do
        {
          data: {
            attributes: {
              delivery_partner_id: delivery_partner.ecf_id,
              secondary_delivery_partner_id: nil,
            },
          },
        }.to_json
      end

      it "omits the secondary delivery partner" do
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a declaration is not provided" do
      subject(:service) do
        described_class.new(
          delivery_partner:,
          secondary_delivery_partner:,
        )
      end

      let(:declaration) { create(:declaration, :started, application:, lead_provider:, course_cohort:, delivery_partner: default_delivery_partner) }

      it "uses the most recent declaration" do
        declaration
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a declaration cannot be found" do
      subject(:service) { described_class.new(delivery_partner:) }

      let(:declaration) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[ChangeDeliveryPartner] Could not find a declaration")
      end
    end
  end
end
