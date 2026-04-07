require "rails_helper"

RSpec.feature "Choose a TTE and provider", :with_default_lead_provider, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  let(:user) { create(:user) }
  let(:course) { Course.find_by(identifier: "tte-early-years") }

  before do
    page.set_rack_session(
      "user_id" => user.id,
      "registration_store" => {
        "course_start_date" => "yes",
        "course_identifier" => course.identifier,
        "lead_provider_id" => "not_chosen",
      },
    )
  end

  scenario "displays the page with correct content" do
    visit "/registration/choose-a-tte-and-provider"

    expect(page).to have_content("Choose a TTE course and provider")
  end

  scenario "back link returns to choose your provider page with selection preserved" do
    visit "/registration/choose-a-tte-and-provider"

    click_link "Back"

    expect(page).to have_current_path("/registration/choose-your-provider")
    expect(page).to have_checked_field("I have not chosen a provider yet", visible: :all)
  end
end
