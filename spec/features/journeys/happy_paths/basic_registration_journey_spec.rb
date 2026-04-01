require "rails_helper"

RSpec.feature "Happy journeys", :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "Stub Teacher Auth Responses"

  context "when JavaScript is enabled", :js do
    scenario("registration journey (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("registration journey (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      expect(page).to have_text(I18n.t("helpers.hint.registration_wizard.course_start_date_one"))
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-course", submit_form: true) do
      expect(page).to have_text("Choose a TTE course")
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose(LeadProvider.first.name, visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      expect(page).to have_text("Do you work in England?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    choose_a_school(js:, name: "open")

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("Funding")
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your TTE information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course start" => "In #{application_course_start_date}",
          "Course" => "Early Years",
          "Provider" => LeadProvider.first.name,
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "A school",
          "Workplace in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    User.last.tap do |user|
      expect(user.email).to eql("user@example.com")
      expect(user.full_name).to eql("John Doe")
      expect(user.trn).to eql("1234567")
      expect(user.trn_verified).to be_truthy
      expect(user.trn_auto_verified).to be_truthy
      expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
      expect(user.national_insurance_number).to be_nil
      expect(user.applications.count).to be(1)

      user.applications.first.tap do |application|
        expect(application.eligible_for_funding).to be_truthy
      end
    end
    if User.last.applications.count == 1
      navigate_to_page(path: "/applications/#{User.last.applications.last.ecf_id}", submit_form: false) do
        expect(page).to have_text(LeadProvider.first.name)
        expect(page).to have_text("Early Years")
      end
    else
      navigate_to_page(path: "/applications", submit_form: false) do
        expect(page).to have_text(LeadProvider.first.name)
        expect(page).to have_text("Early Years")
      end
    end

    visit "/registration/share-provider"

    expect_page_to_have(path: "/", submit_form: false) do
      expect(page).to have_content("Before you start")
    end

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response.merge(
                                                             "active_alert" => false,
                                                             "archived_email" => nil,
                                                             "archived_at" => nil,
                                                             "ecf_id" => latest_application_user.ecf_id,
                                                             "get_an_identity_id_synced_to_ecf" => false,
                                                             "national_insurance_number" => nil,
                                                             "notify_user_for_future_reg" => false,
                                                             "preferred_name" => nil,
                                                             "raw_tra_provider_data" => nil,
                                                             "trn_auto_verified" => true,
                                                             "trn_lookup_status" => nil,
                                                             "trn_verified" => true,
                                                           ))

    deep_compare_application_data(
      "accepted_at" => nil,
      "course_cohort_id" => latest_application.course_cohort_id,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => true,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "kind_of_nursery" => nil,
      "status" => "pending",
      "participant_outcome_state" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: LeadProvider.first.name).id,
      "notes" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
      "institution_id" => Institution.find_by(institution_reference_number: "100000").id,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
      "teacher_catchment_iso_country_code" => "GBR",
      "ukprn" => Institution.find_by(institution_reference_number: "100000").ukprn,
      "primary_establishment" => false,
      "number_of_pupils" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "can_share_choices" => "1",
        # "chosen_provider" => "yes",
        "course_start" => "In #{application_course_start_date}",
        "course_start_date" => "yes",
        "course_identifier" => "tte-early-years",
        # "funding" => "trust",
        "funding_amount" => nil,
        # "funding_eligiblity_status_code" => "ineligible_establishment_type",
        "institution_id" => Institution.find_by(institution_reference_number: "100000").id.to_s,
        "institution_name" => js ? "" : "open",
        "lead_provider_id" => LeadProvider.first.id.to_s,
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "work_setting" => "a_school",
        "works_in_childcare" => "no",
        "works_in_school" => "yes",
      },
    )
  end
end
