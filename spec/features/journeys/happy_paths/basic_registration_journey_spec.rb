require "rails_helper"

RSpec.feature "Happy journeys", :with_default_lead_provider, :with_default_schedules, :with_default_school, type: :feature do
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
    navigate_to_page(path: "/", submit_form: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      expect(page).to have_text("When do you want to start the course?")

      page.choose(CourseCohort.next_open_for(course: Course.reception).name, visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your training provider")
      page.choose(LeadProvider.first.name, visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      expect(page).to have_text("Do you work in England?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("State-funded nursery, pre-school, school or academy trust", visible: :all)
    end

    choose_a_school(js:, name: "open")

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("Funding")
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPD information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course start" => CourseCohort.next_open_for(course: Course.reception).name,
          "Course" => Course.last.name,
          "Provider" => LeadProvider.first.name,
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "State-funded nursery, pre-school, school or academy trust",
          "Workplace in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    User.last.tap do |user|
      expect(user.email).to eql("user@example.com")
      expect(user.full_name).to eql("John Doe")
      expect(user.trn).to eql("1234567")
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
        expect(page).to have_text("NPD excellence in reception teaching")
      end
    else
      navigate_to_page(path: "/applications", submit_form: false) do
        expect(page).to have_text(LeadProvider.first.name)
        expect(page).to have_text("NPD excellence in reception teaching")
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
                                                             "national_insurance_number" => nil,
                                                             "notify_user_for_future_reg" => false,
                                                             "preferred_name" => nil,
                                                             "raw_tra_provider_data" => nil,
                                                             "refresh_token" => nil,
                                                             "refresh_token_updated_at" => nil,
                                                             "trn_lookup_status" => nil,
                                                             "trn_requested_at" => nil,
                                                           ))

    deep_compare_application_data(
      "course_cohort_id" => latest_application.course_cohort_id,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => true,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "status" => "pending",
      "participant_outcome_state" => nil,
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
      "work_setting" => "state_funded_institution",
      "works_in_childcare" => false,
      "works_in_school" => true,
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "can_share_choices" => "1",
        "course_cohort_id" => latest_application.course_cohort_id,
        "course_start" => latest_application.course_cohort.name,
        "course_start_date" => "yes",
        "funding_amount" => nil,
        "institution_id" => Institution.find_by(institution_reference_number: "100000").id.to_s,
        "institution_name" => js ? "" : "open",
        "lead_provider_id" => LeadProvider.first.id.to_s,
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "work_setting" => "state_funded_institution",
      },
    )
  end
end
