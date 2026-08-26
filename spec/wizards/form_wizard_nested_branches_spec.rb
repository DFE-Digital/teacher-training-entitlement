require "rails_helper"

RSpec.describe FormWizard do
  describe "nested branch navigation" do
    subject(:wizard) do
      described_class.new(
        params: {},
        session:,
        registration_journey: journey,
        registration_step: senco_responsibilities,
      )
    end

    let(:session) { {} }
    let(:journey) { RegistrationJourney.find_by!(slug: "npq-inspired-demo") }
    let(:senco_responsibilities) { journey.registration_steps.find_by!(slug: "senco-responsibilities") }

    before do
      Rake::Task["registration_journeys:create_npq_inspired_journey"].invoke
      wizard.state_store.write(
        which_setting_do_you_work_in: "A school or academy trust",
        which_course_do_you_want_to_take: "Special educational needs co-ordinator (SENCO)",
        which_statement_describes_your_senco_role: senco_answer,
      )
    end

    after do
      Rake::Task["registration_journeys:create_npq_inspired_journey"].reenable
    end

    context "when the applicant is already a SENCO" do
      let(:senco_answer) { "I am a SENCO" }

      it "returns to the custom start-date step from the nested join" do
        expect(wizard.previous_step).to eq(:"senco-start-date")
      end
    end

    context "when the applicant is preparing to become a SENCO" do
      let(:senco_answer) { "I am about to become a SENCO" }

      it "returns to the readiness step from the nested join" do
        expect(wizard.previous_step).to eq(:"senco-readiness")
      end
    end
  end

  describe "two-level nested branch navigation" do
    subject(:wizard) do
      described_class.new(
        params: {},
        session: {},
        registration_journey: journey,
        registration_step: maths_leadership,
      )
    end

    let(:journey) { RegistrationJourney.find_by!(slug: "npq-inspired-demo") }
    let(:maths_leadership) { journey.registration_steps.find_by!(slug: "maths-leadership-role") }

    before do
      Rake::Task["registration_journeys:create_npq_inspired_journey"].invoke
      wizard.state_store.write(
        which_setting_do_you_work_in: "A school or academy trust",
        which_course_do_you_want_to_take: "Leading primary mathematics",
        have_you_completed_a_year_of_the_teaching_for_mastery_programme: teaching_for_mastery,
        how_familiar_are_you_with_the_mastery_approach_to_mathematics: maths_approach,
      )
    end

    after do
      Rake::Task["registration_journeys:create_npq_inspired_journey"].reenable
    end

    context "when the applicant can jump directly to the join" do
      let(:teaching_for_mastery) { "Yes" }
      let(:maths_approach) { nil }

      it "returns to the outer mathematics branch question" do
        expect(wizard.previous_step).to eq(:"teaching-for-mastery")
      end
    end

    context "when the applicant understands mastery" do
      let(:teaching_for_mastery) { "No" }
      let(:maths_approach) { "I understand the principles" }

      it "returns to the inner mathematics branch question" do
        expect(wizard.previous_step).to eq(:"maths-mastery-understanding")
      end
    end

    context "when the applicant needs an additional preparation step" do
      let(:teaching_for_mastery) { "No" }
      let(:maths_approach) { "I am new to the approach" }

      it "returns to the nested preparation step" do
        expect(wizard.previous_step).to eq(:"maths-course-preparation")
      end
    end
  end
end
