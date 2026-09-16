require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::LeadProviders do
  subject(:step) { described_class.new(lead_providers:) }

  describe "#lead_providers" do
    let(:lead_providers) do
      {
        "1" => {
          "selected" => "1",
          "url" => url,
          "email" => "provider@example.com",
        },
      }
    end

    context "when the URL has no scheme" do
      let(:url) { "aaa.com" }

      it "prepends http" do
        expect(step.lead_providers.dig("1", "url")).to eq("http://aaa.com")
      end
    end

    context "when the URL already has a scheme" do
      let(:url) { "https://aaa.com" }

      it "keeps the URL as submitted" do
        expect(step.lead_providers.dig("1", "url")).to eq("https://aaa.com")
      end
    end
  end
end
