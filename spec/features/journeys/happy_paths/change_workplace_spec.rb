require "rails_helper"

RSpec.feature "Change workplace", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "Stub Teacher Auth Responses"

  let(:user) { create(:user) }
  let(:school) { create(:school, :with_address) }

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

  scenario "displays previously selected school when returning to choose-school page" do
    visit "/registration/choose-school/change"

    within(".npq-js-reveal") do
      input = find("input[type='text']", visible: true)
      expect(input.value).to eq(school.name_with_address)
    end
  end
end
