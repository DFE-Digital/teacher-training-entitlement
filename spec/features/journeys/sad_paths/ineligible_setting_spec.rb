require "rails_helper"

RSpec.feature "Ineligible setting", :with_default_lead_provider, :with_default_schedules, type: :feature do
  include ApplicationHelper

  let(:user) { create(:user, :with_one_login_id) }
  let(:lead_provider) { LeadProvider.first }
  let(:course) { Course.find_by(identifier: "tte-early-years") }

  context "when work setting is 'other'" do
    before do
      page.set_rack_session(
        "user_id" => user.id,
        "registrations_#{user.id}" => {
          "confirmation" => "yes",
          "course_identifier" => course.identifier,
          "lead_provider_id" => lead_provider.id,
          "teacher_catchment" => "england",
          "work_setting" => "other",
        },
      )
    end

    scenario "displays funding page then continues to funding your course" do
      visit "/reception-registration/ineligible-for-funding"

      expect(page).to have_text("Funding")
      expect(page).to have_text("you do not work in one of the eligible settings")

      click_link "Continue"

      expect(page).to have_current_path("/reception-registration/funding-your-course")
      expect(page).to have_text("I am paying")
    end
  end

  context "when school has ineligible establishment type" do
    let(:school) { create(:school, :ineligible_establishment_type) }

    before do
      page.set_rack_session(
        "user_id" => user.id,
        "registrations_#{user.id}" => {
          "confirmation" => "yes",
          "course_identifier" => course.identifier,
          "lead_provider_id" => lead_provider.id,
          "teacher_catchment" => "england",
          "work_setting" => "a_school",
          "institution_id" => school.institution.id.to_s,
        },
      )
    end

    scenario "displays funding page then continues to funding your course" do
      visit "/reception-registration/ineligible-for-funding"

      expect(page).to have_text("Funding")
      expect(page).to have_text("you do not work in one of the eligible settings")

      click_link "Continue"

      expect(page).to have_current_path("/reception-registration/funding-your-course")
      expect(page).to have_text("I am paying")
    end
  end
end
