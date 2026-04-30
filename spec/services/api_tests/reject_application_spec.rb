require "rails_helper"

RSpec.describe APITests::RejectApplication, type: :model do
  subject(:service) { described_class.new(application:) }

  let(:application) { create(:application, :pending, lead_provider:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }

  let(:expected_body) do
    {
      data: {
        type: "application",
        attributes: {
          reason: "other",
        },
      },
    }.to_json
  end

  let(:expected_url) do
    "http://localhost:3000#{Rails.application.routes.url_helpers.reject_api_v1_application_path(application.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:put).and_return(api_response)
  end

  describe "#call" do
    it "sends a reject application request" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:put).with(
        expected_url,
        body: expected_body,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when an application is not provided" do
      subject(:service) { described_class.new }

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
      subject(:service) { described_class.new }

      let(:application) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[RejectApplication] Could not find a rejectable application")
      end
    end
  end
end
