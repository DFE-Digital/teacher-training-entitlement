require "rails_helper"

RSpec.describe AdminHelper, type: :helper do
  describe "review_status_tag" do
    subject { review_status_tag(review_status) }

    context "with nil" do
      let(:review_status) { nil }

      it { is_expected.to be_nil }
    end

    context "with needs review" do
      let(:review_status) { "Needs review" }

      it { is_expected.to have_css ".govuk-tag--blue", text: "Needs review" }
    end

    context "with awaiting information" do
      let(:review_status) { "Awaiting information" }

      it { is_expected.to have_css ".govuk-tag--yellow", text: "Awaiting information" }
    end

    context "with re-register" do
      let(:review_status) { "Re-register" }

      it { is_expected.to have_css ".govuk-tag--grey", text: "Re-register" }
    end

    context "with decision made" do
      let(:review_status) { "Decision made" }

      it { is_expected.to have_css ".govuk-tag--grey", text: "Decision made" }
    end

    context "with something unexpected" do
      let(:review_status) { "Something unexpected" }

      it { is_expected.to eq "Something unexpected" }
    end
  end
end
