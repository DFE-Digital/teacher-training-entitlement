require "rails_helper"

RSpec.describe RegistrationSteps::BranchTraversal::BranchTree do
  def create_step(registration_journey:, step_class:, **attributes)
    create(:registration_step, registration_journey:, type: step_class.name, **attributes)
  end

  describe "#call" do
    let(:journey) { create(:registration_journey) }
    let(:choice) { create_step(registration_journey: journey, step_class: RegistrationSteps::RadioButtons) }
    let(:path_a) do
      create_step(
        registration_journey: journey,
        step_class: RegistrationSteps::Plain,
        state_store_key: "path_a_answer",
        previous_step_id: choice.id,
      )
    end
    let(:followup) do
      create_step(
        registration_journey: journey,
        step_class: RegistrationSteps::Plain,
        state_store_key: "path_a_followup_answer",
        previous_step_id: path_a.id,
      )
    end
    let(:path_b) do
      create_step(
        registration_journey: journey,
        step_class: RegistrationSteps::Plain,
        state_store_key: "path_b_answer",
        previous_step_id: choice.id,
      )
    end
    let(:join) do
      create_step(
        registration_journey: journey,
        step_class: RegistrationSteps::Plain,
        state_store_key: "shared_answer",
        previous_step_id: followup.id,
      )
    end

    context "when the answer selects a branch" do
      before do
        choice.set_answers!(answers: [
          { name: "A", value: "a", next_step_id: path_a.id },
          { name: "B", value: "b", next_step_id: path_b.id },
        ])
        choice.update!(branch_join_step: join)
      end

      it "returns answer keys on that path and stops before the shared join" do
        branch_tree = described_class.new(registration_journey: journey, registration_step: choice, answers: { choice.answer_key.to_sym => "a" })

        expect(branch_tree.call.map(&:answer_key).map(&:to_sym)).to eq(%i[path_a_answer path_a_followup_answer])
      end
    end

    context "when the answer has no explicit branch destination" do
      let(:step) { create_step(registration_journey: journey, step_class: RegistrationSteps::RadioButtons) }

      before { step.set_answers!(answers: [{ name: "Continue", value: "continue" }]) }

      it "returns no keys" do
        branch_tree = described_class.new(registration_journey: journey, registration_step: step, answers: { step.answer_key.to_sym => "continue" })

        expect(branch_tree.call).to eq([])
      end
    end
  end
end
