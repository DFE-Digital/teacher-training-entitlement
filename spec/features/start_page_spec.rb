require "rails_helper"

RSpec.feature "Start page", type: :feature do
  include_context "Stub Teacher Auth Responses"

  scenario "Navigate to home" do
    visit "/"

    expect(page).to have_text("Before you start")
  end

  scenario "Log in button tracks the One Login start event" do
    visit "/registration/start"

    expect(page).to have_css(
      "[data-google-analytics-event='one_login_started'][data-google-analytics-event-page-path='/registration/start']",
      text: "Log in",
    )
  end
end
