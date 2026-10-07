require "rails_helper"

RSpec.describe "applications/applications/_funding_details.html.erb", type: :view do
  subject(:rendered_partial) do
    render partial: "applications/applications/funding_details", locals: { application: }
    Capybara.string(rendered)
  end

  let(:lead_provider) { create(:lead_provider, name: "Test Provider") }
  let(:application) do
    create(
      :application,
      :for_cohort_starting_on,
      lead_provider:,
      eligible_for_funding:,
      funding_eligiblity_status_code:,
      registration_data:,
      registration_starts_at: Date.new(2025, 4, 1),
    )
  end
  let(:eligible_for_funding) { false }
  let(:funded) { false }
  let(:funding_eligiblity_status_code) { FundingEligibility::INELIGIBLE_SETTING }
  let(:registration_data) { {} }

  before do
    assign(:application, application)
  end

  context "when the application is eligible for scholarship funding" do
    let(:eligible_for_funding) { true }
    let(:funding_eligiblity_status_code) { FundingEligibility::FUNDED_ELIGIBILITY_RESULT }

    it "shows the eligible funding details" do
      expect(rendered_partial).to have_css(".govuk-summary-card__title", text: "Funding details")
      expect(rendered_partial).to have_css(".govuk-tag", text: "Eligible")
      expect(rendered_partial).to have_text("if Test Provider confirms that you have a scholarship funded space")
      expect(rendered_partial).not_to have_text("Course funding")
    end
  end

  context "when the application is not eligible because of setting" do
    let(:registration_data) { { "funding" => "self" } }

    it "shows the course funding row with ineligible_setting text" do
      expect(rendered_partial).to have_css(".govuk-tag", text: "Not eligible")
      expect(rendered_partial).to have_text("Course funding")

      expected_funding_text = ActionView::Base.full_sanitizer.sanitize(I18n.t("funding_details.ineligible_setting"))
      expect(rendered_partial).to have_text(expected_funding_text)
    end
  end

  context "when the application is not eligible because of being previously funded" do
    let(:registration_data) { { "funding" => "self" } }

    before do
      # An application funded on a different course
      create(:application,
             user: application.user,
             eligible_for_funding: true,
             funding_eligiblity_status_code: "funded",
             status: Application::COMPLETED,
             course_cohort: create(:course_cohort,
                                   course: create(:course),
                                   cohort: application.course_cohort.cohort))
    end

    it "shows the course funding row with ineligible_setting text" do
      expect(rendered_partial).to have_css(".govuk-tag", text: "Not eligible")
      expect(rendered_partial).to have_text("Course funding")

      expected_funding_text = ActionView::Base.full_sanitizer.sanitize(I18n.t("funding_details.previously_funded"))
      expect(rendered_partial).to have_text(expected_funding_text)
    end
  end
end
