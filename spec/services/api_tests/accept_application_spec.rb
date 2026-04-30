require "rails_helper"

RSpec.describe APITests::AcceptApplication, type: :model do
  subject(:service) { described_class.new(application:, funded_place:) }

  let(:application) { create(:application, :pending, lead_provider:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:funded_place) { "true" }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }

  let(:expected_body) do
    {
      data: {
        attributes: {
          funded_place: true,
        },
      },
    }.to_json
  end

  let(:expected_url) do
    "http://localhost:3000#{Rails.application.routes.url_helpers.accept_api_v1_application_path(application.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:put).and_return(api_response)
  end

  describe "#call" do
    it "sends an accept application request" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:put).with(
        expected_url,
        body: expected_body,
        headers: hash_including(
          "Authorization" => "Bearer test-token",
          "Content-Type" => "application/json",
        ),
      )
    end

    context "when funded place is false" do
      let(:funded_place) { "false" }

      let(:expected_body) do
        {
          data: {
            attributes: {
              funded_place: false,
            },
          },
        }.to_json
      end

      it "sends false in the payload" do
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when an application is not provided" do
      subject(:service) { described_class.new(funded_place:) }

      let(:application) { create(:application, :pending, lead_provider:) }

      it "uses the most recent pending application" do
        application
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a pending application cannot be found" do
      subject(:service) { described_class.new(funded_place:) }

      let(:application) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[AcceptApplication] Could not find a pending application")
      end
    end
  end
end
