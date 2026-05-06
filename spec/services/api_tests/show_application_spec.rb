require "rails_helper"

RSpec.describe APITests::ShowApplication, type: :model do
  subject(:service) { described_class.new(application:, lead_provider:) }

  let(:application) { create(:application, lead_provider:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "data" => {} }) }

  let(:expected_url) do
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{Rails.application.routes.url_helpers.api_v1_application_path(application.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:get).and_return(api_response)
  end

  describe "#call" do
    it "gets the application" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:get).with(
        expected_url,
        body: nil,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when an application is not provided" do
      subject(:service) { described_class.new }

      let(:application) { create(:application, lead_provider:) }

      it "uses the most recent application and its lead provider" do
        application
        service.call

        expect(HTTParty).to have_received(:get).with(
          expected_url,
          body: nil,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a lead provider cannot be found" do
      subject(:service) { described_class.new(application: nil, lead_provider: nil) }

      let(:application) { nil }
      let(:lead_provider) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[ShowApplication] Could not find a lead provider")
      end
    end
  end
end
