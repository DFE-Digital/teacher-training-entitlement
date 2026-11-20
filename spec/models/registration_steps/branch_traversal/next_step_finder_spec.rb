require "rails_helper"

RSpec.describe RegistrationSteps::BranchTraversal::NextStepFinder do
  def create_step(registration_journey:, step_class:, **attributes)
    create(:registration_step, registration_journey:, type: step_class.name, **attributes)
  end

  describe "#call" do
    let(:journey) { create(:registration_journey) }
    let(:step) { create_step(registration_journey: journey, step_class: RegistrationSteps::RadioButtons) }
    let(:answer_value) { "yes" }
    let(:answers) { { step.answer_key => answer_value } }
    let(:finder) { described_class.new(registration_journey: journey, registration_step: step, answers:) }

    context "when the selected answer has a destination" do
      let(:destination) { create_step(registration_journey: journey, step_class: RegistrationSteps::Plain) }

      before do
        step.set_answers!(answers: [{ name: "Continue", value: answer_value, next_step_id: destination.id }])
      end

      it "returns the answer-specific destination" do
        expect(finder.call).to eq(destination)
      end
    end

    context "when the selected answer has no destination" do
      let(:destination) do
        create_step(
          registration_journey: journey,
          step_class: RegistrationSteps::Plain,
          previous_step_id: step.id,
        )
      end

      before do
        destination
        step.set_answers!(answers: [{ name: "Continue", value: answer_value }])
      end

      it "returns the default next step" do
        expect(finder.call).to eq(destination)
      end
    end
  end
end
