require "rails_helper"

RSpec.describe APITests::VoidDeclaration, type: :model do
  subject(:service) { described_class.new(declaration:) }

  let(:application) { create(:application, :started, lead_provider:) }
  let(:declaration) { create(:declaration, :started, application:, lead_provider:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }

  let(:expected_url) do
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{Rails.application.routes.url_helpers.void_api_v1_declaration_path(declaration.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_CONFIG", lead_provider.name => { token: "test-token" }) if lead_provider
    allow(HTTParty).to receive(:put).and_return(api_response)
  end

  describe "#call" do
    it "sends a void declaration request" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:put).with(
        expected_url,
        body: nil,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when a declaration is not provided" do
      subject(:service) { described_class.new }

      let(:declaration) { create(:declaration, :started, application:, lead_provider:) }

      it "uses the most recent declaration" do
        declaration
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: nil,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a declaration cannot be found" do
      subject(:service) { described_class.new }

      let(:declaration) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[VoidDeclaration] Could not find a declaration")
      end
    end
  end
end
