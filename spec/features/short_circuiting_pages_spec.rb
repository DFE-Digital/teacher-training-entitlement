require "rails_helper"

RSpec.feature "Short circuiting pages", type: :feature do
  include Helpers::JourneyAssertionHelper

  include_context "Stub Teacher Auth Responses"

  context "with the legacy registration journey" do
    scenario "visit /registration/check-answers directly" do
      visit "/registration/check-answers"
      expect(page).to have_current_path("/")
    end
  end

  context "with the dfe-wizard registration journey", :dfe_wizard_registration do
    let!(:course_cohort) { create(:course_cohort) }

    scenario "visit the check answers page of a course directly" do
      visit "/registration/#{course_cohort.course.identifier}/check-answers"
      expect(page).to have_current_path("/registration/#{course_cohort.course.identifier}/course-start-date")
    end
  end
end
