require "rails_helper"

# This is the exact scenario from bug CPDNPQ-2812.
# The main issue is the steps when clicking 'Back' are completely wrong.
# The fix put in was just a quick fix - making the back steps correct will also fix the issue, but it's a larger piece of work (see CPDNPQ-3053).
RSpec.feature "Sad journey", :with_default_lead_provider, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  context "when JavaScript is enabled", :js do
    scenario("teacher catchment not in England (with JS)") { run_scenario }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("teacher catchment not in England (without JS)") { run_scenario }
  end

  def run_scenario
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-course", submit_form: false) do
      click_button "Continue"
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose(LeadProvider.first.name, visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Other", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding")
  end
end
