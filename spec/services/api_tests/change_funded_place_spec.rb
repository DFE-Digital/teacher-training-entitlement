require "rails_helper"

RSpec.describe APITests::ChangeFundedPlace, type: :model do
  subject(:service) { described_class.new(application:, funded_place:) }

  let(:application) { create(:application, :accepted, lead_provider:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:funded_place) { "yes" }
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
    "http://localhost:3000#{Rails.application.routes.url_helpers.change_funded_place_api_v1_application_path(application.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:put).and_return(api_response)
  end

  describe "#call" do
    it "sends a change funded place request" do
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
      let(:funded_place) { "0" }

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

      let(:application) { create(:application, :accepted, lead_provider:) }

      it "uses the most recent accepted application" do
        application
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when an accepted application cannot be found" do
      subject(:service) { described_class.new(funded_place:) }

      let(:application) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[ChangeFundedPlace] Could not find an accepted application")
      end
    end
  end
end
