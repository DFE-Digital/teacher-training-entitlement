require "rails_helper"

RSpec.describe APITests::ListApplications, type: :model do
  subject(:service) { described_class.new(lead_provider:, filters:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:filters) { { status: "pending" } }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "data" => [] }) }

  let(:expected_url) do
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{Rails.application.routes.url_helpers.api_v1_applications_path(filter: filters)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:get).and_return(api_response)
  end

  describe "#call" do
    it "gets the applications list" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:get).with(
        expected_url,
        body: nil,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when a lead provider is not provided" do
      subject(:service) { described_class.new(filters:) }

      it "uses the most recent lead provider" do
        lead_provider
        service.call

        expect(HTTParty).to have_received(:get).with(
          expected_url,
          body: nil,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a lead provider cannot be found" do
      subject(:service) { described_class.new(filters:) }

      let(:lead_provider) { nil }

      before do
        allow(LeadProvider).to receive(:last).and_return(nil)
      end

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[ListApplications] Could not find a lead provider")
      end
    end
  end
end
