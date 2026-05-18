require "rails_helper"

RSpec.feature "Change workplace", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "Stub Teacher Auth Responses"

  let(:user) { create(:user) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :tte_early_years, display: true, lead_provider:) }
  let(:school) { create(:school, :with_address) }

  before do
    page.set_rack_session(
      "user_id" => user.id,
      "registration_store" => {
        "institution_id" => school.institution.id.to_s,
        "confirmation" => "yes",
        "course_identifier" => course.identifier,
        "lead_provider_id" => lead_provider.id.to_s,
        "teacher_catchment" => "england",
        "work_setting" => "a_school",
      },
    )
  end

  scenario "displays previously selected school when returning to choose-school page" do
    visit "/reception-registration/choose-school/change"

    within(".npq-js-reveal") do
      input = find("input[type='text']", visible: true)
      expect(input.value).to eq(school.name_with_address)
    end
  end
end
