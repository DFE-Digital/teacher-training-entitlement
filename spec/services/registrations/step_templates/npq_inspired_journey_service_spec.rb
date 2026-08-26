require "rails_helper"

RSpec.describe Registrations::StepTemplates::NpqInspiredJourneyService do
  describe "#call" do
    it "creates the NPQ-inspired journey steps" do
      journey = RegistrationJourney.create!(name: "NPQ-inspired journey", slug: "npq-inspired")

      expect {
        described_class.new(registration_journey: journey, registration_template: nil).call
      }.to change(journey.registration_steps, :count).by(36)

      expect(journey.registration_steps.order(:order).pluck(:slug)).to eq(%w[
        teacher-catchment
        return-to-teaching-referral
        course-start-date
        work-setting
        choose-school
        school-role
        school-employment-status
        early-years-setting
        ofsted-registration
        choose-early-years-setting
        childcare-registration-help
        early-years-role
        other-employment
        other-education-role
        employer-support
        choose-your-npq
        leadership-responsibility
        teaching-phases
        teaching-experience
        senco-role
        senco-start-date
        senco-readiness
        senco-responsibilities
        teaching-for-mastery
        maths-mastery-understanding
        maths-course-preparation
        maths-leadership-role
        headteacher-status
        headship-stage
        npqh-status
        previous-funding
        course-funding
        choose-your-provider
        provider-check
        share-provider
        check-answers
      ])
    end

    it "sets the main work setting branch choices" do
      journey = RegistrationJourney.create!(name: "NPQ-inspired journey", slug: "npq-inspired")

      described_class.new(registration_journey: journey, registration_template: nil).call

      work_setting = journey.registration_steps.find_by!(slug: "work-setting")
      school = journey.registration_steps.find_by!(slug: "choose-school")
      childcare_kind = journey.registration_steps.find_by!(slug: "early-years-setting")
      other_employment = journey.registration_steps.find_by!(slug: "other-employment")
      course = journey.registration_steps.find_by!(slug: "choose-your-npq")

      expect(work_setting.answer_data).to eq([
        { "name" => "A school or academy trust", "value" => "a_school_or_academy_trust", "next_step_id" => school.id },
        { "name" => "An early years or childcare setting", "value" => "an_early_years_or_childcare_setting", "next_step_id" => childcare_kind.id },
        { "name" => "Another education setting", "value" => "another_education_setting", "next_step_id" => other_employment.id },
      ])
      expect(work_setting.branch_join_step_id).to eq(course.id)
    end

    it "sets the NPQ course branch choices" do
      journey = RegistrationJourney.create!(name: "NPQ-inspired journey", slug: "npq-inspired")

      described_class.new(registration_journey: journey, registration_template: nil).call

      course = journey.registration_steps.find_by!(slug: "choose-your-npq")
      leadership_responsibility = journey.registration_steps.find_by!(slug: "leadership-responsibility")
      senco_status = journey.registration_steps.find_by!(slug: "senco-role")
      teaching_for_mastery = journey.registration_steps.find_by!(slug: "teaching-for-mastery")
      headteacher_status = journey.registration_steps.find_by!(slug: "headteacher-status")
      previous_funding = journey.registration_steps.find_by!(slug: "previous-funding")

      expect(course.answer_data).to eq([
        { "name" => "Leading teaching", "value" => "leading_teaching", "next_step_id" => leadership_responsibility.id },
        { "name" => "Special educational needs co-ordinator (SENCO)", "value" => "special_educational_needs_co_ordinator_senco", "next_step_id" => senco_status.id },
        { "name" => "Leading primary mathematics", "value" => "leading_primary_mathematics", "next_step_id" => teaching_for_mastery.id },
        { "name" => "Early headship coaching offer", "value" => "early_headship_coaching_offer", "next_step_id" => headteacher_status.id },
      ])
      expect(course.branch_join_step_id).to eq(previous_funding.id)
    end

    it "configures the custom SENCO start date step" do
      journey = RegistrationJourney.create!(name: "NPQ-inspired journey", slug: "npq-inspired")

      described_class.new(registration_journey: journey, registration_template: nil).call

      senco_start_date = journey.registration_steps.find_by!(slug: "senco-start-date")

      expect(senco_start_date).to have_attributes(
        name: "When did you start as a SENCO?",
        type: RegistrationSteps::CustomStep::TYPE,
        order: 21,
      )
      expect(senco_start_date.custom_step_class_name).to eq("Forms::NpqInspired::SencoStartDateStepForm")
    end
  end
end
