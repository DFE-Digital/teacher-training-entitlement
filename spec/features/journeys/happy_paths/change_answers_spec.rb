require "rails_helper"

RSpec.feature "Change answers from check answers", :with_default_lead_provider, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include Helpers::ReceptionRegistrationPathHelper

  include_context "Stub Teacher Auth Responses"

  let(:lead_provider) { LeadProvider.first }

  before { Flipper.enable(Feature::REGISTRATION_DFE_WIZARD) }

  def answer_up_to_check_answers
    start_registration
    choose_current_course_start_date
    choose_provider(lead_provider)
    choose_teacher_catchment("No")
    continue_past_ineligible_funding
    choose_course_funding("I am paying")
    agree_to_share_provider_information
  end

  scenario "keeping the same answer returns to check answers" do
    answer_up_to_check_answers
    click_link "Change Workplace in England"

    expect(page).to have_current_path(journey_path("/registration/teacher-catchment"), ignore_query: true)
    expect(page).to have_checked_field("No", visible: :all)

    click_button "Continue"

    expect(page).to have_current_path(journey_path("/registration/check-answers"))
    expect(page).to have_text("Workplace in England")
  end

  scenario "going back from the answer being changed returns to check answers" do
    answer_up_to_check_answers
    click_link "Change Provider"
    click_link "Back"

    expect(page).to have_current_path(journey_path("/registration/check-answers"))
  end

  scenario "changing the workplace to England asks the new questions before returning to check answers" do
    answer_up_to_check_answers
    click_link "Change Workplace in England"

    choose "Yes", visible: :all
    click_button "Continue"

    expect(page).to have_current_path(journey_path("/registration/work-setting"), ignore_query: true)
    choose "Private nursery, pre-school or school", visible: :all
    click_button "Continue"

    expect(page).to have_current_path(journey_path("/registration/ineligible-for-funding"), ignore_query: true)
    click_link "Continue"

    expect(page).to have_current_path(journey_path("/registration/funding-your-course"), ignore_query: true)
    choose "My trust is paying", visible: :all
    click_button "Continue"

    expect(page).to have_current_path(journey_path("/registration/check-answers"))
    expect(page).to have_text("Private nursery, pre-school or school")
    expect(page).to have_text("My trust is paying")
  end

  scenario "changing the work setting to a state-funded school asks for the school" do
    answer_up_to_check_answers
    click_link "Change Workplace in England"
    choose "Yes", visible: :all
    click_button "Continue"
    choose "Other", visible: :all
    click_button "Continue"
    click_link "Continue"
    choose "I am paying", visible: :all
    click_button "Continue"

    click_link "Change Work setting"
    choose "State-funded nursery, pre-school, school or academy trust", visible: :all
    click_button "Continue"

    expect(page).to have_current_path(journey_path("/registration/choose-school"), ignore_query: true)
  end

  scenario "a submitted teacher starting again sees no previous answers" do
    answer_up_to_check_answers
    submit_check_answers
    expect(page).to have_text("Registration submitted")

    visit journey_path("/registration/course-start-date")

    expect(page).to have_no_checked_field(visible: :all)
  end
end
