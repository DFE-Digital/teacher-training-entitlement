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
      "registrations_#{user.id}" => {
        "institution_id" => school.institution.id.to_s,
        "confirmation" => "yes",
        "lead_provider_id" => lead_provider.id.to_s,
        "teacher_catchment" => "england",
        "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
      },
    )
  end

  scenario "displays previously selected school when returning to choose-school page" do
    visit "/reception-registration/choose-school/change"

    expect(page).to have_field("What is the name of your workplace?", with: school.name_with_address)
    expect(page).to have_css("#choose-school-institution-id-field-select[value='#{school.institution.id}']", visible: :all)
  end
end
