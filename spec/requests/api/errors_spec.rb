require "rails_helper"

RSpec.describe "Error responses", type: :request do
  include_context "when errors are rendered"

  describe "not found" do
    it "returns a JSON error response" do
      api_get "/api/v1/thisdoesnotexist"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("The requested endpoint does not exist")
      expect(response.content_type).to match(/application\/json.*/)
    end

    it "keeps the V1 envelope for unknown V1 paths" do
      api_get "/api/v1/thisdoesnotexist"
      expect(JSON.parse(response.body)).to have_key("error")
    end

    context "when the request is for API guidance docs" do
      it "returns an HTML response" do
        api_get "/api/guidance/thisdoesnotexist"
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include "The page you were looking for doesn’t exist."
        expect(response.content_type).to match(/text\/html.*/)
      end
    end

    context "when the request is for API swagger docs" do
      it "returns an HTML response" do
        api_get "/api/docs/thisdoesnotexist"
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include "The page you were looking for doesn’t exist."
        expect(response.content_type).to match(/text\/html.*/)
      end
    end
  end

  describe "internal server error" do
    before do
      allow(Applications::Query).to receive(:new).and_raise(StandardError)
    end

    it "returns a JSON error response" do
      api_get "/api/v1/applications"
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to eq %({"error":"Internal server error"})
      expect(response.content_type).to match(/application\/json.*/)
    end
  end

  describe "unprocessable entity" do
    before do
      allow(Applications::Query).to receive(:new).and_raise(ActiveRecord::RecordInvalid)
    end

    it "returns a JSON error response" do
      api_get "/api/v1/applications"
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to eq %({"error":"Unprocessable entity"})
      expect(response.content_type).to match(/application\/json.*/)
    end
  end

  describe "API V2 errors rendered by the exceptions app" do
    include_context "with API V2 enabled"

    let(:lead_provider) { create(:lead_provider) }

    {
      StandardError => [500, "Internal server error"],
      ActiveRecord::RecordInvalid => [422, "Unprocessable entity"],
    }.each do |exception, (status, title)|
      it "returns a JSON:API #{status} for #{exception}" do
        allow(API::V2::Applications::Query).to receive(:new).and_raise(exception)
        api_get "/api/v2/applications", lead_provider:, params: { filter: { course: "x" } }

        expect([response.status, response.media_type, JSON.parse(response.body)]).to eq(
          [status, "application/vnd.api+json", { "errors" => [{ "status" => status.to_s, "title" => title }] }],
        )
      end
    end

    it "keeps the V1 envelope for V1 server errors" do
      allow(Applications::Query).to receive(:new).and_raise(StandardError)
      api_get "/api/v1/applications"

      expect(JSON.parse(response.body)).to eq("error" => "Internal server error")
    end
  end
end
