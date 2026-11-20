require "rails_helper"

RSpec.describe RegistrationSteps::BranchTraversal::PreviousStepFinder do
  def create_step(registration_journey:, step_class:, **attributes)
    create(:registration_step, registration_journey:, type: step_class.name, **attributes)
  end

  describe "#call" do
    context "when a branch answer leads to the join" do
      let(:journey) { create(:registration_journey) }
      let(:choice) do
        create_step(
          registration_journey: journey,
          step_class: RegistrationSteps::RadioButtons,
          state_store_key: "path_choice",
        )
      end
      let(:path_a) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: choice.id)
      end
      let(:followup) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: path_a.id)
      end
      let(:path_b) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: choice.id)
      end
      let(:join) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: followup.id)
      end
      let(:answers) { { path_choice: "a" } }
      let(:finder) { described_class.new(registration_journey: journey, registration_step: join, answers:) }

      before do
        choice.set_answers!(answers: [
          { name: "A", value: "a", next_step_id: path_a.id },
          { name: "B", value: "b", next_step_id: path_b.id },
        ])
        choice.update!(branch_join_step: join)
      end

      it "returns the last step on the selected branch" do
        expect(finder.call).to eq(followup)
      end
    end

    context "when the target is the branch root" do
      let(:journey) { create(:registration_journey) }
      let(:choice) { create_step(registration_journey: journey, step_class: RegistrationSteps::RadioButtons, state_store_key: "choice") }
      let(:branch_root) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: choice.id)
      end
      let(:join) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: branch_root.id)
      end
      let(:finder) do
        described_class.new(registration_journey: journey, registration_step: branch_root, answers: { choice: "a" })
      end

      before do
        choice.set_answers!(answers: [{ name: "A", value: "a", next_step_id: branch_root.id }])
        choice.update!(branch_join_step: join)
      end

      it "returns the branch decision step" do
        expect(finder.call).to eq(choice)
      end
    end

    context "when the target has multiple conditional incoming routes" do
      let(:journey) { create(:registration_journey) }
      let(:teacher_catchment) do
        create_step(
          registration_journey: journey,
          step_class: RegistrationSteps::RadioButtons,
          name: "Do you work in England?",
          state_store_key: "teacher_catchment",
        )
      end
      let(:work_setting) do
        create_step(
          registration_journey: journey,
          step_class: RegistrationSteps::RadioButtons,
          name: "Tell us where you work",
          state_store_key: "work_setting",
          previous_step_id: teacher_catchment.id,
        )
      end
      let(:ineligible_step) do
        create_step(
          registration_journey: journey,
          step_class: RegistrationSteps::ViewComponent,
          name: "Funding eligibility result",
          previous_step_id: work_setting.id,
        )
      end
      let(:share_provider) { create_step(registration_journey: journey, step_class: RegistrationSteps::CheckAnswers) }
      let(:path_a) { create_step(registration_journey: journey, step_class: RegistrationSteps::Plain) }
      let(:path_b) { create_step(registration_journey: journey, step_class: RegistrationSteps::Plain) }
      let(:answers) { { teacher_catchment: Institution::OTHER } }
      let(:finder) do
        described_class.new(registration_journey: journey, registration_step: ineligible_step, answers:)
      end

      before do
        teacher_catchment.set_answers!(answers: [
          { name: "Yes", value: Institution::ENGLAND_SUBDIVISION_CODE, next_step_id: work_setting.id },
          { name: "No", value: Institution::OTHER, next_step_id: ineligible_step.id },
        ])
        teacher_catchment.update!(branch_join_step: share_provider)
        work_setting.set_answers!(answers: [
          { name: "State-funded", value: Institution::STATE_FUNDED_INSTITUTION, next_step_id: path_a.id },
          { name: "Private", value: Institution::PRIVATE_INSTITUTION, next_step_id: ineligible_step.id },
          { name: "Other", value: Institution::OTHER, next_step_id: ineligible_step.id },
        ])
        work_setting.update!(branch_join_step: share_provider)
      end

      it "returns the selected decision step instead of the configured default predecessor" do
        expect(finder.call).to eq(teacher_catchment)
      end

      context "when the applicant chose a work setting that routes to the target" do
        let(:answers) do
          {
            teacher_catchment: Institution::ENGLAND_SUBDIVISION_CODE,
            work_setting: Institution::PRIVATE_INSTITUTION,
          }
        end

        it "returns the work setting step" do
          expect(finder.call).to eq(work_setting)
        end
      end
    end

    context "when multiple selected branches lead into the same step" do
      let(:journey) { create(:registration_journey) }
      let(:join) { create_step(registration_journey: journey, step_class: RegistrationSteps::Plain) }
      let(:choices) do
        %w[first_choice second_choice].map do |answer_key|
          choice = create_step(
            registration_journey: journey,
            step_class: RegistrationSteps::RadioButtons,
            state_store_key: answer_key,
          )
          choice.set_answers!(answers: [{ name: "Continue", value: "continue", next_step_id: join.id }])
          choice.update!(branch_join_step: join)
          choice
        end
      end
      let(:answers) { choices.to_h { |choice| [choice.answer_key.to_sym, "continue"] } }
      let(:finder) { described_class.new(registration_journey: journey, registration_step: join, answers:) }

      it "raises an argument error" do
        expect { finder.call }
          .to raise_error(ArgumentError, "Registration step #{join.id} has multiple selected branch predecessors")
      end
    end
  end
end
