require "rails_helper"

RSpec.feature "Previously funded participant", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include ApplicationHelper

  let(:user) { create(:user, :with_one_login_id) }
  let(:school) { create(:school, :with_address) }
  let(:lead_provider) { create(:lead_provider, :with_courses) }
  let(:course) { lead_provider.courses.last }

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
        "institution_id" => school.institution.id.to_s,
      },
    )
  end

  scenario "displays funding page with previously funded message (AC1)" do
    visit "/registration/ineligible-for-funding"

    expect(page).to have_text("Funding eligibility result")
    expect(page).to have_text("You've already been allocated scholarship funding")
  end

  scenario "continue button navigates to funding your course page (AC2)" do
    visit "/registration/ineligible-for-funding"

    click_link "Continue"

    expect(page).to have_current_path("/registration/funding-your-course")
    expect(page).to have_text("How are you funding your course?")
  end
end
