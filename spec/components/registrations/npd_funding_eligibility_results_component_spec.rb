require "rails_helper"

RSpec.describe Registrations::NpdFundingEligibilityResultsComponent, type: :component do
  let(:funding_eligibility_result) { Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING }
  let(:state_store) do
    ActiveSupport::HashWithIndifferentAccess.new(
      funding_eligibility_result:,
    )
  end
  let(:wizard_step) { instance_double(Registrations::StepDefinitions::FormStep, state_store:) }

  before do
    render_inline(described_class.new(wizard_step:, form: nil))
  end

  it "explains that an applicant in an ineligible setting must pay another way" do
    expect(page).to have_text("You're not eligible for scholarship funding")
    expect(page).to have_text("pay for the course another way")
    expect(page).to have_css("ul.govuk-list--bullet li", count: 2)
  end

  context "when the applicant is eligible for funding" do
    let(:funding_eligibility_result) { Registrations::FundingEligibilityConstants::FUNDED }

    it "shows the funding result and next steps" do
      expect(page).to have_text("You're eligible for funding.")
      expect(page).to have_css("h2.govuk-heading-m", text: "What happens next")
      expect(page).to have_css("ol.govuk-list--number li", count: 2)
    end
  end

  context "when the applicant is outside England" do
    let(:funding_eligibility_result) { Registrations::FundingEligibilityConstants::NOT_IN_ENGLAND }

    it "explains that the applicant is not eligible because they are outside England" do
      expect(page).to have_text("You're not eligible because you're not in England.")
      expect(page).to have_css("ul.govuk-list--bullet li", count: 2)
    end
  end

  context "when the applicant was previously funded" do
    let(:funding_eligibility_result) { Registrations::FundingEligibilityConstants::PREVIOUSLY_FUNDED }

    it "explains the previous funding and how to continue" do
      expect(page).to have_text("You've already been allocated scholarship funding for the course.")
      expect(page).to have_text("If you're taking the course again")
      expect(page).to have_text("Continue to register.")
      expect(page).to have_css("ul.govuk-list--bullet li", count: 2)
      expect(page).not_to have_css("ol.govuk-list--number")
    end
  end
end
