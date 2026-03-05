require "rails_helper"
require "url_builder"

RSpec.describe UrlBuilder do
  describe ".build_url" do
    subject { described_class.build_url("/callback") }

    context "when HOSTING_DOMAIN is set" do
      before { allow(ENV).to receive(:[]).with("HOSTING_DOMAIN").and_return("https://example.com/") }

      it { is_expected.to eq(URI("https://example.com/callback")) }
    end

    context "when HOSTING_DOMAIN is not set" do
      before { allow(ENV).to receive(:[]).with("HOSTING_DOMAIN").and_return(nil) }

      it { is_expected.to eq("/callback") }
    end
  end
end
