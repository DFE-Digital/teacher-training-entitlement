require "rails_helper"

RSpec.describe "API V2 feature flag", type: :request do
  let(:lead_provider) { create(:lead_provider) }
  let!(:application) { create(:application, lead_provider:) }
  let(:json) { JSON.parse(response.body) }

  context "when API V2 is disabled" do
    before { Flipper.disable(Feature::API_V2_ENABLED) }

    ["/api/v2/applications", "/api/v2/applications/%<id>s", "/api/v2/thisdoesnotexist"].each do |path|
      it "returns a JSON:API not found error for #{path}" do
        api_get(sprintf(path, id: application.ecf_id), lead_provider:)

        expect([response.status, response.media_type, json.keys, json["errors"].first["status"]]).to eq(
          [404, "application/vnd.api+json", %w[errors], "404"],
        )
      end
    end

    it "returns not found before validating show parameters" do
      api_get("/api/v2/applications/#{application.ecf_id}", lead_provider:, params: { sort: "bogus" })

      expect(response).to have_http_status(:not_found)
    end

    it "does not query applications" do
      allow(API::V2::Applications::Query).to receive(:new)
      api_get("/api/v2/applications", lead_provider:)

      expect(API::V2::Applications::Query).not_to have_received(:new)
    end

    it "keeps API V1 available" do
      api_get("/api/v1/applications", lead_provider:)

      expect([response.status, json["data"].map { |a| a["id"] }]).to eq([200, [application.ecf_id]])
    end
  end

  context "when API V2 is enabled" do
    before { Flipper.enable(Feature::API_V2_ENABLED) }

    it "serves API V2" do
      api_get("/api/v2/applications", lead_provider:)

      expect([response.status, json["data"].map { |a| a["id"] }]).to eq([200, [application.ecf_id]])
    end

    it "keeps API V1 available" do
      api_get("/api/v1/applications", lead_provider:)

      expect([response.status, json["data"].map { |a| a["id"] }]).to eq([200, [application.ecf_id]])
    end
  end
end
