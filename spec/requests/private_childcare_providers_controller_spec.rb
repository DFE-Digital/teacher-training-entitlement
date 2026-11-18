require "rails_helper"

RSpec.describe PrivateChildcareProvidersController do
  describe "#index" do
    let!(:provider) { create(:private_childcare_provider, provider_urn: "EY123456").institution }

    before do
      create(:private_childcare_provider, provider_urn: "EY999999")
      create(:school, urn: "EY123400")
    end

    it "returns matching private childcare providers only" do
      get "/private_childcare_providers.json?name=EY1234"

      expect(JSON.parse(response.body).pluck("urn")).to eq([provider.urn])
    end

    it "returns the legacy identifier" do
      get "/private_childcare_providers.json?name=EY1234"

      expect(JSON.parse(response.body).first["identifier"]).to eq("PrivateChildcareProvider-EY123456")
    end
  end
end
