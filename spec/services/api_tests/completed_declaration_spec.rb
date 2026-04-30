require "rails_helper"

RSpec.describe APITests::CompletedDeclaration, type: :model do
  subject(:service) { described_class.new(application:, has_passed:, delivery_partner:) }

  let(:application) { create(:application, :started, lead_provider:) }
  let(:lead_provider) { create(:lead_provider, delivery_partner: default_delivery_partner) }
  let(:default_delivery_partner) { create(:delivery_partner) }
  let(:delivery_partner) { create(:delivery_partner) }
  let(:has_passed) { "true" }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
  let(:declaration_date) { Time.zone.local(2026, 4, 29, 12, 30, 45) }

  let(:expected_body) do
    {
      data: {
        attributes: {
          declaration_date: declaration_date.utc.iso8601,
          delivery_partner_id: delivery_partner.ecf_id,
          has_passed: true,
        },
      },
    }.to_json
  end

  let(:expected_url) do
    "http://localhost:3000#{Rails.application.routes.url_helpers.completed_declaration_api_v1_application_path(application.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:post).and_return(api_response)
  end

  describe "#call" do
    it "posts a completed declaration request" do
      travel_to(declaration_date) do
        expect(service.call).to eq(api_response)
      end

      expect(HTTParty).to have_received(:post).with(
        expected_url,
        body: expected_body,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when has_passed is false" do
      let(:has_passed) { "no" }

      let(:expected_body) do
        {
          data: {
            attributes: {
              declaration_date: declaration_date.utc.iso8601,
              delivery_partner_id: delivery_partner.ecf_id,
              has_passed: false,
            },
          },
        }.to_json
      end

      it "sends false in the payload" do
        travel_to(declaration_date) { service.call }

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a delivery partner is not provided" do
      let(:delivery_partner) { nil }

      let(:expected_body) do
        {
          data: {
            attributes: {
              declaration_date: declaration_date.utc.iso8601,
              delivery_partner_id: default_delivery_partner.ecf_id,
              has_passed: true,
            },
          },
        }.to_json
      end

      it "uses the lead provider's first delivery partner" do
        travel_to(declaration_date) { service.call }

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when an application is not provided" do
      subject(:service) { described_class.new(has_passed:, delivery_partner:) }

      let(:application) { create(:application, :started, lead_provider:) }

      it "uses the most recent started application" do
        application

        travel_to(declaration_date) { service.call }

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a started application cannot be found" do
      subject(:service) { described_class.new(has_passed:, delivery_partner:) }

      let(:application) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[StartedDeclaration] Could not find a started application")
      end
    end
  end
end
