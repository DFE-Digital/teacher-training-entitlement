require "rails_helper"

RSpec.describe RegistrationSteps::BranchTraversal::DefaultNextStep do
  def create_step(registration_journey:, step_class:, **attributes)
    create(:registration_step, registration_journey:, type: step_class.name, **attributes)
  end

  describe "#call" do
    context "with a branching journey" do
      let(:journey) { create(:registration_journey) }
      let(:choice) { create_step(registration_journey: journey, step_class: RegistrationSteps::RadioButtons) }
      let(:path_a) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: choice.id)
      end
      let(:path_b) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: choice.id)
      end
      let(:join) do
        create_step(registration_journey: journey, step_class: RegistrationSteps::Plain, previous_step_id: path_a.id)
      end

      before do
        choice.set_answers!(answers: [
          { name: "A", value: "a", next_step_id: path_a.id },
          { name: "B", value: "b", next_step_id: path_b.id },
        ])
        choice.update!(branch_join_step: join)
      end

      it "uses the branch join as each path's default next step and returns nil after the join" do
        expect(described_class.new(registration_journey: journey, registration_step: path_a).call).to eq(join)
        expect(described_class.new(registration_journey: journey, registration_step: path_b).call).to eq(join)
        expect(described_class.new(registration_journey: journey, registration_step: join).call).to be_nil
      end
    end

    context "when a step has multiple default next steps" do
      let(:journey) { create(:registration_journey) }
      let(:step) { create_step(registration_journey: journey, step_class: RegistrationSteps::Plain) }
      let(:next_steps) do
        2.times.map do |index|
          create_step(
            registration_journey: journey,
            step_class: RegistrationSteps::Plain,
            name: "Next step #{index}",
            previous_step_id: step.id,
          )
        end
      end

      before { next_steps }

      it "raises an argument error" do
        expect { described_class.new(registration_journey: journey, registration_step: step).call }
          .to raise_error(ArgumentError, "Registration step #{step.id} has multiple default next steps")
      end
    end
  end
end
