require "rails_helper"

RSpec.feature "Registration wizard paths", :no_js, :with_default_lead_provider, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include Helpers::ReceptionRegistrationPathHelper
  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  scenario "state-funded school not in England without funded place" do
    lead_provider = LeadProvider.first

    start_registration
    choose_current_course_start_date
    choose_provider(lead_provider)
    choose_teacher_catchment("No")
    continue_past_ineligible_funding
    choose_course_funding("My trust is paying")
    agree_to_share_provider_information
    submit_check_answers

    application = Application.sole

    aggregate_failures "application fields" do
      expect(application.course).to eq(Course.reception)
      expect(application.lead_provider).to eq(lead_provider)
      expect(application.institution).to be_nil
      expect(application.user.email).to eq(user_email)

      expect(application).to have_attributes(
        eligible_for_funding: false,
        funded_place: nil,
        funding_choice: "trust",
        funding_eligiblity_status_code: "not_in_england",
        institution_id: nil,
        teacher_catchment: "another",
        teacher_catchment_country: nil,
        teacher_catchment_iso_country_code: nil,
        targeted_support_funding_eligibility: false,
        ukprn: nil,
        work_setting: nil,
      )

      expect(application.raw_application_data).to match(
        "can_share_choices" => "1",
        "course_start" => Course.reception.next_open_cohort.name,
        "course_start_date" => "yes",
        "funding" => "trust",
        "funding_amount" => nil,
        "lead_provider_id" => lead_provider.id.to_s,
        "submitted" => true,
        "teacher_catchment" => "another",
        "teacher_catchment_country" => nil,
      )
    end
  end
end
