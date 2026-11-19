require "rails_helper"

RSpec.describe RegistrationStep do
  describe ".new" do
    it "uses the HTML component STI type for simple question types" do
      registration_step = described_class.new(type: "RegistrationSteps::RadioButtons")

      expect(registration_step).to be_a(RegistrationSteps::HtmlComponent)
    end

    it "uses the ViewComponent STI type for component-backed steps" do
      registration_step = described_class.new(type: "RegistrationSteps::ViewComponent")

      expect(registration_step).to be_a(RegistrationSteps::ViewComponent)
    end

    it "uses the base type for other step types" do
      registration_step = described_class.new(type: "RegistrationSteps::CheckAnswers")

      expect(registration_step).to be_a(described_class)
      expect(registration_step).not_to be_a(RegistrationSteps::HtmlComponent)
      expect(registration_step).not_to be_a(RegistrationSteps::ViewComponent)
      expect(registration_step).not_to be_a(RegistrationSteps::HtmlPartial)
    end
  end

  describe "#set_answers!" do
    let(:registration_journey) { create(:registration_journey, name: "Demo", slug: "demo") }
    let(:registration_step) do
      create(
        :registration_step,
        registration_journey:,
        name: "Work setting",
        type: "RegistrationSteps::RadioButtons",
        config: {},
      )
    end

    it "stores answer name/value pairs" do
      registration_step.set_answers!(
        answers: [
          { "name" => "State-funded nursery", "value" => Institution::STATE_FUNDED_INSTITUTION },
        ],
      )

      expect(registration_step.registration_step_answers).to contain_exactly(
        have_attributes(
          name: "State-funded nursery",
          value: Institution::STATE_FUNDED_INSTITUTION,
          position: 0,
        ),
      )
    end

    it "preserves a missing answer value" do
      registration_step.set_answers!(
        answers: [
          { "name" => "State-funded nursery, pre-school, school or academy trust" },
        ],
      )

      expect(registration_step.registration_step_answers).to contain_exactly(
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
      registration_step = described_class.new(name: "Choose your provider")

      expect(registration_step.answer_key).to eq("choose_your_provider")
    end

    it "uses the configured answer key" do
      registration_step = described_class.new(
        name: "Choose your provider",
        state_store_key: "lead_provider_id",
      )

      expect(registration_step.answer_key).to eq("lead_provider_id")
    end
  end

  describe "#add_service!" do
    let(:registration_journey) { create(:registration_journey, name: "Demo", slug: "demo") }
    let(:registration_step) do
      create(
        :registration_step,
        registration_journey:,
        name: "Choose a snack",
        type: "RegistrationSteps::RadioButtons",
        config: {
          "services" => [
            { "class_name" => "ExistingService", "execute_point" => "after_update" },
          ],
        },
      )
    end

    it "appends a service to the step configuration" do
      registration_step.add_service!(
        class_name: Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name,
        execute_point: :before_show,
      )

      expect(registration_step.reload.config["services"]).to eq(
        [
          { "class_name" => "ExistingService", "execute_point" => "after_update" },
          { "class_name" => Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name, "execute_point" => "before_show" },
        ],
      )
    end

    context "when the execute point is unsupported" do
      let(:registration_step) { described_class.new(type: "RegistrationSteps::RadioButtons", config: {}) }

      it "raises an argument error" do
        expect {
          registration_step.add_service!(class_name: "ExampleService", execute_point: :before_step)
        }.to raise_error(ArgumentError, "execute_point must be one of before_show, after_update - was given 'before_step'")
      end
    end
  end

  describe "#redirect_target_for" do
    it "returns an answer-level redirect path" do
      registration_step = described_class.new(type: "RegistrationSteps::RadioButtons", config: {})
      registration_step.registration_step_answers.build(name: "No", value: "no", redirect_path: "/not-eligible")

      expect(registration_step.redirect_target_for(answer: "no", state_store: {}))
        .to eq("/not-eligible")
    end

    it "returns a step-level redirect path from the state store" do
      registration_step = described_class.new(
        type: "RegistrationSteps::CheckAnswers",
        redirect_state_store_key: "application_path",
      )

      expect(registration_step.redirect_target_for(answer: nil, state_store: { application_path: "/applications/123" }))
        .to eq("/applications/123")
    end

    it "replaces path params with the configured state store value" do
      registration_step = described_class.new(
        type: "RegistrationSteps::CheckAnswers",
        redirect_path: "/applications/:ecf_id",
        redirect_state_store_key: "application_ecf_id",
      )

      expect(registration_step.redirect_target_for(answer: nil, state_store: { application_ecf_id: "abc-123" }))
        .to eq("/applications/abc-123")
    end

    it "prefers answer-level redirects over step-level redirects" do
      registration_step = described_class.new(type: "RegistrationSteps::RadioButtons", config: {}, redirect_path: "/fallback")
      registration_step.registration_step_answers.build(name: "No", value: "no", redirect_path: "/not-eligible")

      expect(registration_step.redirect_target_for(answer: "no", state_store: {}))
        .to eq("/not-eligible")
    end

    it "does not return redirects outside the app" do
      registration_step = described_class.new(type: "RegistrationSteps::RadioButtons", config: {})
      registration_step.registration_step_answers.build(name: "No", value: "no", redirect_path: "https://example.com")

      expect(registration_step.redirect_target_for(answer: "no", state_store: {}))
        .to be_nil
    end
  end

  describe "#display_answer_value" do
    it "returns the configured answer name for a stored answer value" do
      registration_journey = create(:registration_journey, name: "Demo", slug: "demo")
      registration_step = create(:registration_step,
                                 registration_journey:,
                                 name: "Work setting",
                                 type: "RegistrationSteps::RadioButtons",
                                 config: {})
      registration_step.set_answers!(
        answers: [
          {
            "name" => "State-funded nursery, pre-school, school or academy trust",
            "value" => Institution::STATE_FUNDED_INSTITUTION,
          },
        ],
      )

      expect(registration_step.display_answer_value(value: Institution::STATE_FUNDED_INSTITUTION))
        .to eq("State-funded nursery, pre-school, school or academy trust")
    end

    it "returns the configured answer name for an explicit stored answer value" do
      registration_step = described_class.new(type: "RegistrationSteps::Checkboxes", config: {})
      registration_step.registration_step_answers.build(name: "Toasted seeds", value: "toasted_seeds", position: 0)

      expect(registration_step.display_answer_value(value: "toasted_seeds"))
        .to eq("Toasted seeds")
    end

    it "returns the raw value when no configured answer matches" do
      registration_step = described_class.new(type: "RegistrationSteps::Checkboxes", config: {})
      registration_step.registration_step_answers.build(name: "Toasted seeds", position: 0)

      expect(registration_step.display_answer_value(value: "raw-value"))
        .to eq("raw-value")
    end
  end
end
