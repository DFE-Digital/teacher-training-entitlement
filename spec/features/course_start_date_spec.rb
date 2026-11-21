require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  registration_journeys do
    scenario "course start date" do
      seed_course_cohort_in_registration_store

      start_registration_from_root

      expect(page).not_to have_content("Before you start")

      expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
        expect(page).to have_text("Course start")
        expect(page).to have_text("When do you want to start a course?")
      end
    end
  end
end
