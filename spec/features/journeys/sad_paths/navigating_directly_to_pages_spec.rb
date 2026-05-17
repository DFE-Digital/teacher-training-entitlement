require "rails_helper"

RSpec.feature "Sad journeys", :no_js, :npq, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  before do
    navigate_to_page(path: "/", submit_form: false) do
      page.click_button("Start now")
    end
  end

  steps_that_require_course = %w[
    check-answers
    choose-your-provider
    possible-funding
  ]

  ReceptionRegistrations::FormWizard::STEP_NAMES
    .map(&:to_s).each do |step|
    scenario "Navigating directly to the #{step} page does not raise an error" do
      visit "/reception-registration/#{step}"
      if steps_that_require_course.include?(step)
        expect(page).to have_current_path("/reception-registration/course-start-date")
      else
        expect(page).to have_current_path("/reception-registration/#{step}")
      end
    end
  end
end
