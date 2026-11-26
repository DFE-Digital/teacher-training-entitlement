require "rails_helper"

RSpec.describe Registrations::StepDefinition do
  describe ".new" do
    it "keeps the step definition separate from its DfE Wizard form class" do
      step_definition = described_class.new(step_class: Registrations::StepDefinitions::RadioButtons)

      expect(step_definition).to be_a(described_class)
      expect(step_definition.step_class).to eq(Registrations::StepDefinitions::RadioButtons)
      expect(step_definition.form_class).to be < Registrations::StepDefinitions::RadioButtons
    end

    it "reuses compatible DfE Wizard form classes across step definitions" do
      first_step = described_class.new(
        name: "Choose a provider",
        step_class: Registrations::StepDefinitions::RadioButtons,
        state_store_key: "lead_provider_id",
        requires_answer: true,
        required_answer_message: "Choose a provider",
      )
      second_step = described_class.new(
        name: "Choose a provider",
        step_class: Registrations::StepDefinitions::RadioButtons,
        state_store_key: "lead_provider_id",
        requires_answer: true,
        required_answer_message: "Choose a provider",
      )

      expect(first_step.form_class).to equal(second_step.form_class)
      expect(first_step.form_class).to include(DfE::Wizard::Step)
      expect(first_step.form_class.permitted_params).to eq([:lead_provider_id])
    end

    it "uses separate form classes when the step attributes differ" do
      first_step = described_class.new(
        name: "Choose a provider",
        step_class: Registrations::StepDefinitions::RadioButtons,
        state_store_key: "lead_provider_id",
      )
      second_step = described_class.new(
        name: "Choose a provider",
        step_class: Registrations::StepDefinitions::RadioButtons,
        state_store_key: "provider_id",
      )

      expect(first_step.form_class).not_to equal(second_step.form_class)
    end
  end

  describe "#set_answer_options!" do
    let(:journey_definition) { create(:journey_definition, name: "Demo", slug: "demo") }
    let(:step_definition) do
      create(
        :step_definition,
        journey_definition:,
        name: "Work setting",
        type: "Registrations::StepDefinitions::RadioButtons",
        config: {},
      )
    end

    it "stores answer name/value pairs" do
      step_definition.set_answer_options!(
        answers: [
          { "name" => "State-funded nursery", "value" => Institution::STATE_FUNDED_INSTITUTION },
        ],
      )

      expect(step_definition.answer_options).to contain_exactly(
        have_attributes(
          name: "State-funded nursery",
          value: Institution::STATE_FUNDED_INSTITUTION,
          position: 0,
        ),
      )
    end

    it "preserves a missing answer value" do
      step_definition.set_answer_options!(
        answers: [
          { "name" => "State-funded nursery, pre-school, school or academy trust" },
        ],
      )

      expect(step_definition.answer_options).to contain_exactly(
        have_attributes(
          name: "State-funded nursery, pre-school, school or academy trust",
          value: nil,
          position: 0,
        ),
      )
    end
  end

  describe "#answer_key" do
    it "defaults to the underscored step name" do
      step_definition = described_class.new(name: "Choose your provider")

      expect(step_definition.answer_key).to eq("choose_your_provider")
    end

    it "uses the configured answer key" do
      step_definition = described_class.new(
        name: "Choose your provider",
        state_store_key: "lead_provider_id",
      )

      expect(step_definition.answer_key).to eq("lead_provider_id")
    end
  end

  describe "#add_service!" do
    let(:journey_definition) { create(:journey_definition, name: "Demo", slug: "demo") }
    let(:step_definition) do
      create(
        :step_definition,
        journey_definition:,
        name: "Choose a snack",
        type: "Registrations::StepDefinitions::RadioButtons",
        config: {
          "services" => [
            { "class_name" => "ExistingService", "execute_point" => "after_update" },
          ],
        },
      )
    end

    it "appends a service to the step configuration" do
      step_definition.add_service!(
        class_name: Registrations::Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name,
        execute_point: :before_show,
      )

      expect(step_definition.config["services"]).to eq(
        [
          { "class_name" => "ExistingService", "execute_point" => "after_update" },
          { "class_name" => Registrations::Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name, "execute_point" => "before_show" },
        ],
      )
    end

    context "when the execute point is unsupported" do
      let(:step_definition) { described_class.new(type: "Registrations::StepDefinitions::RadioButtons", config: {}) }

      it "raises an argument error" do
        expect {
          step_definition.add_service!(class_name: "ExampleService", execute_point: :before_step)
        }.to raise_error(ArgumentError, "execute_point must be one of before_show, after_update - was given 'before_step'")
      end
    end
  end

  describe "#redirect_target_for" do
    it "returns an answer-level redirect path" do
      step_definition = described_class.new(type: "Registrations::StepDefinitions::RadioButtons", config: {})
      step_definition.set_answer_options!(answers: [{ name: "No", value: "no", redirect_path: "/not-eligible" }])

      expect(step_definition.redirect_target_for(answer: "no", state_store: {}))
        .to eq("/not-eligible")
    end

    it "returns a step-level redirect path from the state store" do
      step_definition = described_class.new(
        type: "Registrations::StepDefinitions::CheckAnswers",
        redirect_state_store_key: "application_path",
      )

      expect(step_definition.redirect_target_for(answer: nil, state_store: { application_path: "/applications/123" }))
        .to eq("/applications/123")
    end

    it "replaces path params with the configured state store value" do
      step_definition = described_class.new(
        type: "Registrations::StepDefinitions::CheckAnswers",
        redirect_path: "/applications/:ecf_id",
        redirect_state_store_key: "application_ecf_id",
      )

      expect(step_definition.redirect_target_for(answer: nil, state_store: { application_ecf_id: "abc-123" }))
        .to eq("/applications/abc-123")
    end

    it "prefers answer-level redirects over step-level redirects" do
      step_definition = described_class.new(type: "Registrations::StepDefinitions::RadioButtons", config: {}, redirect_path: "/fallback")
      step_definition.set_answer_options!(answers: [{ name: "No", value: "no", redirect_path: "/not-eligible" }])

      expect(step_definition.redirect_target_for(answer: "no", state_store: {}))
        .to eq("/not-eligible")
    end

    it "does not return redirects outside the app" do
      step_definition = described_class.new(type: "Registrations::StepDefinitions::RadioButtons", config: {})
      step_definition.set_answer_options!(answers: [{ name: "No", value: "no", redirect_path: "https://example.com" }])

      expect(step_definition.redirect_target_for(answer: "no", state_store: {}))
        .to be_nil
    end
  end

  describe "#display_answer_value" do
    it "returns the configured answer name for a stored answer value" do
      journey_definition = create(:journey_definition, name: "Demo", slug: "demo")
      step_definition = create(:step_definition,
                               journey_definition:,
                               name: "Work setting",
                               type: "Registrations::StepDefinitions::RadioButtons",
                               config: {})
      step_definition.set_answer_options!(
        answers: [
          {
            "name" => "State-funded nursery, pre-school, school or academy trust",
            "value" => Institution::STATE_FUNDED_INSTITUTION,
          },
        ],
      )

      expect(step_definition.display_answer_value(value: Institution::STATE_FUNDED_INSTITUTION))
        .to eq("State-funded nursery, pre-school, school or academy trust")
    end

    it "returns the configured answer name for an explicit stored answer value" do
      step_definition = described_class.new(type: "Registrations::StepDefinitions::Checkboxes", config: {})
      step_definition.set_answer_options!(answers: [{ name: "Toasted seeds", value: "toasted_seeds" }])

      expect(step_definition.display_answer_value(value: "toasted_seeds"))
        .to eq("Toasted seeds")
    end

    it "returns the raw value when no configured answer matches" do
      step_definition = described_class.new(type: "Registrations::StepDefinitions::Checkboxes", config: {})
      step_definition.set_answer_options!(answers: [{ name: "Toasted seeds" }])

      expect(step_definition.display_answer_value(value: "raw-value"))
        .to eq("raw-value")
    end
  end
end
