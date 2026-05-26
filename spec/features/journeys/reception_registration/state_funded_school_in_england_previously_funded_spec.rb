require "rails_helper"

RSpec.feature "Registration wizard paths", :no_js, :with_default_lead_provider, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include Helpers::ReceptionRegistrationPathHelper
  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  scenario "state-funded school in England when the user has previously been funded" do
    lead_provider = LeadProvider.first
    institution = Institution.find_by!(institution_reference_number: "100000")
    previously_funded_user = create(:user, trn: user_trn)
    create(:application, :accepted, :eligible_for_funding, user: previously_funded_user, course: Course.reception, cohort: create(:cohort, :unique))

    start_registration
    choose_current_course_start_date
    choose_provider(lead_provider)
    choose_teacher_catchment("Yes")
    choose_work_setting("State-funded nursery, pre-school, school or academy trust")
    choose_a_school(js: false, name: "open")
    continue_past_ineligible_funding
    choose_course_funding("I am paying")
    agree_to_share_provider_information
    submit_check_answers

    application = Application.order(:created_at, :id).last

    aggregate_failures "application fields" do
      expect(application.course).to eq(Course.reception)
      expect(application.lead_provider).to eq(lead_provider)
      expect(application.institution).to eq(institution)
      expect(application.user.email).to eq(user_email)

      expect(application).to have_attributes(
        eligible_for_funding: false,
        funded_place: nil,
        funding_choice: "self",
        funding_eligiblity_status_code: "previously_funded",
        institution_id: institution.id,
        on_submission_trn: nil,
        primary_establishment: false,
        review_status: nil,
        status: Application::PENDING,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        targeted_support_funding_eligibility: false,
        ukprn: institution.ukprn,
        work_setting: Institution::STATE_FUNDED_INSTITUTION,
      )

      expect(application.raw_application_data).to match(
        "can_share_choices" => "1",
        "course_identifier" => Course.reception.identifier,
        "course_start" => "In #{application_course_start_date}",
        "course_start_date" => "yes",
        "funding" => "self",
        "funding_amount" => nil,
        "institution_id" => institution.id.to_s,
        "institution_name" => "open",
        "lead_provider_id" => lead_provider.id.to_s,
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
      )
    end
  end
end
