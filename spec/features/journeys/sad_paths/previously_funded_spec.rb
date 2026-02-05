require "rails_helper"

RSpec.feature "Previously funded participant", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include ApplicationHelper

  let(:user) { create(:user, :with_get_an_identity_id) }
  let(:school) { create(:school, :with_address) }
  let(:lead_provider) { LeadProvider.find_by(name: "Ambition Institute") }
  let(:course) { Course.find_by(identifier: "tte-early-years") }

  before do
    create(:application,
           :accepted,
           :eligible_for_funding,
           user:,
           school:,
           course:,
           lead_provider:,
           funded_place: true)

    page.set_rack_session(
      "user_id" => user.id,
      "registration_store" => {
        "course_start_date" => "yes",
        "course_identifier" => course.identifier,
        "lead_provider_id" => lead_provider.id,
        "teacher_catchment" => "england",
        "work_setting" => "a_school",
        "works_in_school" => "yes",
        "institution_identifier" => "School-#{school.urn}",
      },
    )
  end

  scenario "displays funding page with previously funded message (AC1)" do
    visit "/registration/ineligible-for-funding"

    expect(page).to have_text("Funding")
    expect(page).to have_text("You've already been allocated scholarship funding")
  end

  scenario "continue button navigates to funding your course page (AC2)" do
    visit "/registration/ineligible-for-funding"

    click_link "Continue"

    expect(page).to have_current_path("/registration/funding-your-course")
    expect(page).to have_text("How are you funding your course?")
  end
end
