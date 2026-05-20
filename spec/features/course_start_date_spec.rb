require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  scenario "course start date" do
    navigate_to_page(path: "/", submit_form: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/reception-registration/course-start-date", submit_form: true) do
      expect(page).to have_text("Choose your course start date")
      expect(page).to have_text("Registrations are currently open for courses starting in #{Cohort.course_start_date}.")
      expect(page).to have_text("Do you want to start a course in #{Cohort.course_start_date}?")
    end
  end
end
