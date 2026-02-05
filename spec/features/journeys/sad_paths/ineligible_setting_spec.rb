require "rails_helper"

RSpec.feature "Ineligible setting participant (AC3-4)", :with_default_schedules, type: :feature do
  include ApplicationHelper

  let(:user) { create(:user, :with_get_an_identity_id) }
  let(:lead_provider) { LeadProvider.find_by(name: "Ambition Institute") }
  let(:course) { Course.find_by(identifier: "tte-early-years") }

  before do
    page.set_rack_session(
      "user_id" => user.id,
      "registration_store" => {
        "course_start_date" => "yes",
        "course_identifier" => course.identifier,
        "lead_provider_id" => lead_provider.id,
        "teacher_catchment" => "england",
        "work_setting" => "other",
      },
    )
  end

  scenario "displays funding page then continues to funding your course" do
    visit "/registration/ineligible-for-funding"

    expect(page).to have_text("Funding")
    expect(page).to have_text("You're not eligible for scholarship funding")
    expect(page).to have_text("you do not work in one of the eligible settings")

    click_link "Continue"

    expect(page).to have_current_path("/registration/funding-your-course")
    expect(page).to have_text("How are you funding your course?")
  end
end
