require "rails_helper"

RSpec.describe Registrations::Steps::Create do
  let(:registration_journey) { create(:registration_journey, name: "Demo", slug: "demo") }
  let(:service_attributes) do
    {
      registration_journey:,
      step_class: RegistrationSteps::RadioButtons,
      answers:,
      previous_step_id: nil,
      config: {},
    }
  end

  describe "#call" do
    context "with answers" do
      let(:answers) do
        [
          { "name" => "Yes", "hint" => "Continue", "value" => "yes" },
          { "name" => " " },
        ]
      end

      it "creates the step and its named answers" do
        registration_step = described_class.new(
          **service_attributes,
          name: "Do you agree?",
        ).call

        expect(registration_step).to have_attributes(
          name: "Do you agree?",
          type: "RegistrationSteps::RadioButtons",
          persisted?: true,
        )
        expect(registration_step.registration_step_answers).to contain_exactly(
          have_attributes(name: "Yes", hint: "Continue", value: "yes", position: 0),
        )
      end
    end

    context "with a branch join" do
      let(:answers) { [{ "name" => "Yes", "next_step_id" => branch_destination.id }] }
      let(:branch_destination) do
        create(:registration_step,
               registration_journey:,
               name: "Destination",
               type: "RegistrationSteps::Plain",
               config: {})
      end

      it "validates the branch using the answers built before the first save" do
        registration_step = described_class.new(
          **service_attributes,
          name: "Choose a path",
          branch_join_step_id: branch_destination.id,
        ).call

        expect(registration_step).to be_persisted
        expect(registration_step.branch_join_step).to eq(branch_destination)
        expect(registration_step.registration_step_answers.first.next_step).to eq(branch_destination)
      end
    end

    context "with an invalid branch" do
      let(:answers) { [{ "name" => "Yes" }] }

      it "rolls back step creation when branch validation fails" do
        expect {
          described_class.new(
            **service_attributes,
            name: "Choose a path",
            branch_join_step_id: create(:registration_step,
                                        registration_journey:,
                                        name: "Join",
                                        type: "RegistrationSteps::Plain",
                                        config: {}).id,
          ).call
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(registration_journey.registration_steps.where(name: "Choose a path")).to be_empty
      end
    end
  end
end
