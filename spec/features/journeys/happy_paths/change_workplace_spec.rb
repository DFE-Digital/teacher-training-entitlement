require "rails_helper"

RSpec.feature "Change workplace", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "Stub Teacher Auth Responses"

  let(:user) { create(:user) }
  let(:school) { create(:school, :with_address) }

  context "with the legacy registration journey" do
    before do
      page.set_rack_session(
        "user_id" => user.id,
        "registration_store" => {
          "works_in_school" => "yes",
          "institution_id" => school.institution.id.to_s,
          "course_start_date" => "yes",
          "teacher_catchment" => "england",
          "work_setting" => "a_school",
        },
      )
    end

    scenario "displays previously selected school when returning to choose-school page", :js do
      visit "/registration/choose-school/change"

      within(".npq-js-reveal") do
        input = find("input[type='text']", visible: true)
        expect(input.value).to eq(school.name_with_address)
      end
    end
  end

  context "with the dfe-wizard registration journey", :dfe_wizard_registration do
    let(:course_cohort) { create(:course_cohort) }
    let(:course) { course_cohort.course }

    before do
      page.set_rack_session(
        "user_id" => user.id,
        "registration" => {
          course.identifier => {
            "course_start_date" => course_cohort.ecf_id,
            "lead_provider_id" => course_cohort.lead_providers.first.id.to_s,
            "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE,
            "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
            "institution_id" => school.institution.id.to_s,
          },
        },
      )
    end

    scenario "displays previously selected school when changing it from check answers", :js do
      visit "/registration/#{course.identifier}/choose-school?return_to_review=choose_school"

      within(".npq-js-reveal") do
        input = find("input[type='text']", visible: true)
        expect(input.value).to eq(school.name_with_address)
      end
    end
  end
end
