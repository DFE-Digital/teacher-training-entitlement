require "rails_helper"

RSpec.describe Registrations::StepTemplates::Courses::NpdService do
  describe "#call" do
    it "appends the classic NPD registration steps to the registration journey" do
      journey = RegistrationJourney.create!(name: "NPD journey", slug: "npd-journey")
      journey.registration_steps.create!(
        name: "Existing step",
        slug: "existing-step",
        type: "Radio buttons",
        order: 1,
        config: {},
      )
      registration_template = RegistrationTemplate.create!(
        name: "NPD funding eligibility",
      )

      expect {
        described_class.new(registration_journey: journey, registration_template:).call
      }.to change(journey.registration_steps, :count).by(11)

      expect(journey.registration_steps.order(:order).last(11).pluck(:slug)).to eq(%w[
        course-start-date
        choose-your-provider
        teacher-catchment
        work-setting
        choose-school
        possible-funding
        ineligible-for-funding
        funding-your-course
        share-provider
        check-answers
        cannot-register-yet
      ])

      course_start_date = journey.registration_steps.find_by!(slug: "course-start-date")
      provider = journey.registration_steps.find_by!(slug: "choose-your-provider")
      teacher_catchment = journey.registration_steps.find_by!(slug: "teacher-catchment")
      work_setting = journey.registration_steps.find_by!(slug: "work-setting")
      workplace = journey.registration_steps.find_by!(slug: "choose-school")
      possible_funding = journey.registration_steps.find_by!(slug: "possible-funding")
      ineligible_for_funding = journey.registration_steps.find_by!(slug: "ineligible-for-funding")
      funding_your_course = journey.registration_steps.find_by!(slug: "funding-your-course")
      share_provider = journey.registration_steps.find_by!(slug: "share-provider")
      check_answers = journey.registration_steps.find_by!(slug: "check-answers")
      cannot_register_yet = journey.registration_steps.find_by!(slug: "cannot-register-yet")

      expect(course_start_date).to have_attributes(
        name: "Choose your course start date",
        answer_key: "course_start_date",
        type: "Custom view",
        order: 2,
      )
      expect(course_start_date.custom_view_class_name)
        .to eq("Registrations::NpdCourseStartDateComponent")
      expect(course_start_date.answer_data).to eq([
        { "name" => "Yes", "value" => "yes" },
        { "name" => "I want to start at a later date", "value" => "later", "next_step_id" => cannot_register_yet.id },
      ])

      expect(provider).to have_attributes(
        name: "Select your training provider",
        answer_key: "lead_provider_id",
        type: "Radio buttons",
        order: 3,
      )
      expect(provider.text_data).to eq([])
      expect(teacher_catchment).to have_attributes(
        name: "Do you work in England?",
        answer_key: "teacher_catchment",
        type: "Radio buttons",
        order: 4,
      )
      expect(teacher_catchment.answer_data).to eq([
        { "name" => "Yes", "value" => Questionnaires::TeacherCatchment::ENGLAND },
        { "name" => "No", "value" => Questionnaires::TeacherCatchment::NOT_ENGLAND, "next_step_id" => ineligible_for_funding.id },
      ])
      expect(teacher_catchment.branch_join_step_id).to eq(share_provider.id)

      expect(work_setting).to have_attributes(
        name: "Tell us where you work",
        answer_key: "work_setting",
        type: "Radio buttons",
        order: 5,
      )
      expect(work_setting.answer_data).to eq([
        { "name" => "State-funded nursery, pre-school, school or academy trust", "value" => Institution::STATE_FUNDED_INSTITUTION },
        { "name" => "Private nursery, pre-school or school", "value" => Institution::PRIVATE_INSTITUTION, "next_step_id" => ineligible_for_funding.id },
        { "name" => "Other", "value" => Institution::OTHER, "next_step_id" => ineligible_for_funding.id },
      ])
      expect(work_setting.branch_join_step_id).to eq(share_provider.id)

      expect(workplace).to have_attributes(
        name: "Select your workplace",
        answer_key: "institution_id",
        type: "Choose institution",
        order: 6,
      )

      expect(possible_funding).to have_attributes(
        name: "Funding eligibility result",
        type: "Custom view",
        order: 7,
      )
      expect(possible_funding.previous_step_id).to eq(workplace.id)
      expect(possible_funding.custom_view_class_name)
        .to eq("Registrations::NpdFundingEligibilityResultsComponent")
      expect(possible_funding.services_to_run(execute_point: :before_show))
        .to eq(["Registrations::FundingEligibility::NpdService"])

      expect(ineligible_for_funding).to have_attributes(
        name: "Funding eligibility result",
        type: "Custom view",
        order: 8,
      )

      expect(funding_your_course).to have_attributes(
        name: "How are you funding your course?",
        answer_key: "funding",
        type: "Radio buttons",
        order: 9,
      )

      expect(share_provider).to have_attributes(
        name: "Sharing your NPD information",
        answer_key: "can_share_choices",
        type: "Checkboxes",
        order: 10,
      )

      expect(check_answers).to have_attributes(
        name: "Check answers",
        type: "Check answers",
        order: 11,
        redirect_path: "/applications/:ecf_id",
        redirect_state_store_key: "application_ecf_id",
      )
    end
  end
end
