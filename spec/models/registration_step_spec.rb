require "rails_helper"

RSpec.describe RegistrationStep do
  describe ".new" do
    it "uses the HTML component STI type for simple question types" do
      registration_step = described_class.new(type: "Radio buttons")

      expect(registration_step).to be_a(RegistrationSteps::HtmlComponent)
    end

    it "uses the custom step STI type for custom steps" do
      registration_step = described_class.new(type: "Custom step")

      expect(registration_step).to be_a(RegistrationSteps::CustomStep)
    end

    it "uses the base type for other step types" do
      registration_step = described_class.new(type: "Check answers")

      expect(registration_step).to be_a(described_class)
      expect(registration_step).not_to be_a(RegistrationSteps::HtmlComponent)
      expect(registration_step).not_to be_a(RegistrationSteps::CustomStep)
    end
  end

  describe "#answer_data" do
    it "reads answers from the answers configuration" do
      registration_step = described_class.new(
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "answers" => [{ "name" => "Yes" }],
          },
        },
      )

      expect(registration_step.answer_data).to eq([{ "name" => "Yes" }])
    end

    it "does not read the retired questions configuration" do
      registration_step = described_class.new(
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "questions" => [{ "name" => "Legacy answer" }],
          },
        },
      )

      expect(registration_step.answer_data).to be_empty
    end
  end

  describe "#step_class" do
    it "uses a radio button form with answer validation for radio button steps" do
      registration_step = described_class.new(type: "Radio buttons")

      expect(registration_step.step_class).to eq(Forms::RadioButtonsStepForm)
    end

    it "uses the default form for non-radio simple question steps" do
      registration_step = described_class.new(type: "Checkboxes")

      expect(registration_step.step_class).to eq(Forms::RegistrationStepForm)
    end
  end

  describe "#set_answers!" do
    it "stores answer name/value pairs" do
      registration_journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      registration_step = registration_journey.registration_steps.create!(
        name: "Work setting",
        type: "Radio buttons",
        config: {},
      )

      registration_step.set_answers!(
        answers: [
          { "name" => "State-funded nursery", "value" => Institution::STATE_FUNDED_INSTITUTION },
        ],
      )

      expect(registration_step.answer_data).to eq([
        { "name" => "State-funded nursery", "value" => Institution::STATE_FUNDED_INSTITUTION },
      ])
    end

    it "defaults blank values to the underscored answer name" do
      registration_journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      registration_step = registration_journey.registration_steps.create!(
        name: "Work setting",
        type: "Radio buttons",
        config: {},
      )

      registration_step.set_answers!(
        answers: [
          { "name" => "State-funded nursery, pre-school, school or academy trust" },
        ],
      )

      expect(registration_step.answer_data).to eq([
        { "name" => "State-funded nursery, pre-school, school or academy trust", "value" => "state_funded_nursery_pre_school_school_or_academy_trust" },
      ])
    end
  end

  describe "#available_services" do
    it "returns services that inherit from Registrations::BaseStepService" do
      registration_step = described_class.new

      expect(registration_step.available_services)
        .to include("Registrations::Courses::Npd::CompletionService")
    end
  end

  describe "#answer_key" do
    it "defaults to the underscored step name" do
      registration_step = described_class.new(name: "Choose your provider")

      expect(registration_step.answer_key).to eq("choose_your_provider")
      expect(registration_step.stored_answer_keys).to eq([:choose_your_provider])
    end

    it "uses the configured answer key" do
      registration_step = described_class.new(
        name: "Choose your provider",
        answer_key: "lead_provider_id",
      )

      expect(registration_step.answer_key).to eq("lead_provider_id")
      expect(registration_step.stored_answer_keys).to eq([:lead_provider_id])
    end
  end

  describe "#set_service!" do
    it "sets a service which can run before the step" do
      registration_journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      registration_step = registration_journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      registration_step.set_service!(
        class_name: "Registrations::Courses::Npd::CompletionService",
        execute_point: "before_step",
      )

      expect(registration_step.reload.services_to_run(execute_point: :before_step))
        .to eq(["Registrations::Courses::Npd::CompletionService"])
    end
  end

  describe "#add_redirect!" do
    it "persists redirect configuration" do
      registration_journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      registration_step = registration_journey.registration_steps.create!(
        name: "Check answers",
        slug: "check-answers",
        type: "Check answers",
        config: {},
      )

      registration_step.add_redirect!(
        redirect_path: "/applications/:ecf_id",
        redirect_state_store_key: "application_ecf_id",
      )

      expect(registration_step.reload).to have_attributes(
        redirect_path: "/applications/:ecf_id",
        redirect_state_store_key: "application_ecf_id",
      )
    end
  end

  describe "#redirect_target_for" do
    it "returns an answer-level redirect path" do
      registration_step = described_class.new(
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "No", "value" => "no", "redirect" => { "path" => "/not-eligible" } },
            ],
          },
        },
      )

      expect(registration_step.redirect_target_for(answer: "no", state_store: {}))
        .to eq("/not-eligible")
    end

    it "returns a step-level redirect path from the state store" do
      registration_step = described_class.new(
        type: "Check answers",
        redirect_state_store_key: "application_path",
      )

      expect(registration_step.redirect_target_for(answer: nil, state_store: { application_path: "/applications/123" }))
        .to eq("/applications/123")
    end

    it "replaces path params with the configured state store value" do
      registration_step = described_class.new(
        type: "Check answers",
        redirect_path: "/applications/:ecf_id",
        redirect_state_store_key: "application_ecf_id",
      )

      expect(registration_step.redirect_target_for(answer: nil, state_store: { application_ecf_id: "abc-123" }))
        .to eq("/applications/abc-123")
    end

    it "prefers answer-level redirects over step-level redirects" do
      registration_step = described_class.new(
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "No", "value" => "no", "redirect" => { "path" => "/not-eligible" } },
            ],
          },
        },
        redirect_path: "/fallback",
      )

      expect(registration_step.redirect_target_for(answer: "no", state_store: {}))
        .to eq("/not-eligible")
    end

    it "does not return redirects outside the app" do
      registration_step = described_class.new(
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "No", "value" => "no", "redirect" => { "path" => "https://example.com" } },
            ],
          },
        },
      )

      expect(registration_step.redirect_target_for(answer: "no", state_store: {}))
        .to be_nil
    end
  end
end
