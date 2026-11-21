require "rails_helper"

RSpec.feature "Start page", type: :feature do
  include_context "Stub Teacher Auth Responses"

  scenario "Navigate to home" do
    visit "/"

    expect(page).to have_text("Before you start")
  end

  context "with the dfe-wizard registration journey", :dfe_wizard_registration do
    let!(:course_cohort) { create(:course_cohort) }

    scenario "Navigate to home when signed out" do
      allow_any_instance_of(ApplicationController).to receive(:session).and_call_original

      visit "/"

      expect(page).to have_current_path("/registration/#{course_cohort.course.identifier}/sign-in")
      expect(page).to have_text("Before you start")
    end
  end
end
