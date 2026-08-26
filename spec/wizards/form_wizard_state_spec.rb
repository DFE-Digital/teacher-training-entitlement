require "rails_helper"

RSpec.describe FormWizard do
  describe "#save_current_step" do
    it "returns true when a radio button step has a selected answer" do
      journey = RegistrationJourney.create!(name: "Simple journey", slug: "simple-journey")
      step = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {
          "radio_buttons" => {
            "answers" => [{ "name" => "Coffee", "value" => "coffee" }],
          },
        },
      )
      wizard = described_class.new(
        params: ActionController::Parameters.new("choose-a-drink" => { step_answer: "coffee" }),
        session: {},
        registration_journey: journey,
        registration_step: step,
      )

      expect(wizard.save_current_step).to be true
    end

    it "returns false when a radio button step has no selected answer" do
      journey = RegistrationJourney.create!(name: "Simple journey", slug: "simple-journey")
      step = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {
          "radio_buttons" => {
            "answers" => [{ "name" => "Coffee" }],
          },
        },
      )
      wizard = described_class.new(
        params: ActionController::Parameters.new("choose-a-drink" => {}),
        session: {},
        registration_journey: journey,
        registration_step: step,
      )

      expect(wizard.save_current_step).to be false
      expect(wizard.current_step.errors[:step_answer]).to include("Select an answer")
    end
  end

  describe "#store_current_step_answers" do
    it "stores a simple step answer under the configured step name" do
      journey = RegistrationJourney.create!(name: "Simple journey", slug: "simple-journey")
      step = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {
          "radio_buttons" => {
            "answers" => [{ "name" => "Coffee" }],
          },
        },
      )
      wizard = described_class.new(
        params: ActionController::Parameters.new("choose-a-drink" => { step_answer: "Coffee" }),
        session: {},
        registration_journey: journey,
        registration_step: step,
      )

      wizard.store_current_step_answers

      expect(wizard.state_store.read.to_h.symbolize_keys).to eq(choose_a_drink: "Coffee")
    end

    it "stores a simple step answer under a custom answer key" do
      journey = RegistrationJourney.create!(name: "Simple journey", slug: "simple-journey")
      step = journey.registration_steps.create!(
        name: "Choose your provider",
        answer_key: "lead_provider_id",
        slug: "choose-your-provider",
        type: "Radio buttons",
        order: 1,
        config: {
          "radio_buttons" => {
            "answers" => [{ "name" => "Provider One" }],
          },
        },
      )
      wizard = described_class.new(
        params: ActionController::Parameters.new("choose-your-provider" => { step_answer: "Provider One" }),
        session: {},
        registration_journey: journey,
        registration_step: step,
      )

      wizard.store_current_step_answers

      expect(wizard.state_store.read.to_h.symbolize_keys).to eq(lead_provider_id: "Provider One")
    end

    it "uses a custom answer key when clearing answers belonging to the previously selected branch" do
      journey = RegistrationJourney.create!(name: "Branch journey", slug: "branch-journey")
      choice = journey.registration_steps.create!(
        name: "Choose a drink",
        answer_key: "drink_choice",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {},
      )
      coffee_detail = journey.registration_steps.create!(
        name: "Choose your coffee",
        answer_key: "coffee_detail",
        slug: "choose-your-coffee",
        type: "Radio buttons",
        order: 2,
        config: { "previous_step_id" => choice.id },
      )
      tea_detail = journey.registration_steps.create!(
        name: "Choose your tea",
        answer_key: "tea_detail",
        slug: "choose-your-tea",
        type: "Radio buttons",
        order: 3,
        config: { "previous_step_id" => choice.id },
      )
      choice.set_answers!(
        answers: [
          { "name" => "Coffee", "next_step_id" => coffee_detail.id },
          { "name" => "Tea", "next_step_id" => tea_detail.id },
        ],
      )
      wizard = described_class.new(
        params: ActionController::Parameters.new("choose-a-drink" => { step_answer: "tea" }),
        session: {},
        registration_journey: journey,
        registration_step: choice,
      )
      wizard.state_store.write(
        drink_choice: "coffee",
        coffee_detail: "Black",
      )

      wizard.store_current_step_answers

      expect(wizard.state_store.read.to_h.symbolize_keys).to eq(drink_choice: "tea")
    end

    it "clears answers belonging to the previously selected branch" do
      journey = RegistrationJourney.create!(name: "Branch journey", slug: "branch-journey")
      choice = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {},
      )
      coffee_detail = journey.registration_steps.create!(
        name: "Choose your coffee",
        slug: "choose-your-coffee",
        type: "Radio buttons",
        order: 2,
        config: { "previous_step_id" => choice.id },
      )
      tea_detail = journey.registration_steps.create!(
        name: "Choose your tea",
        slug: "choose-your-tea",
        type: "Radio buttons",
        order: 3,
        config: { "previous_step_id" => choice.id },
      )
      choice.set_answers!(
        answers: [
          { "name" => "Coffee", "next_step_id" => coffee_detail.id },
          { "name" => "Tea", "next_step_id" => tea_detail.id },
        ],
      )
      wizard = described_class.new(
        params: ActionController::Parameters.new("choose-a-drink" => { step_answer: "tea" }),
        session: {},
        registration_journey: journey,
        registration_step: choice,
      )
      wizard.state_store.write(
        choose_a_drink: "coffee",
        choose_your_coffee: "Black",
      )

      wizard.store_current_step_answers

      expect(wizard.state_store.read.to_h.symbolize_keys).to eq(choose_a_drink: "tea")
    end

    it "stores the permitted fields from a custom step" do
      journey = RegistrationJourney.create!(name: "Custom journey", slug: "custom-journey")
      step = journey.registration_steps.create!(
        name: "Cool step",
        slug: "cool-step",
        type: "Custom step",
        order: 1,
        config: {
          "custom_step" => {
            "custom_step_class_name" => "Forms::RegisterForThing::CoolStepForm",
          },
        },
      )
      wizard = described_class.new(
        params: ActionController::Parameters.new(
          "cool-step" => {
            something: "One",
            something_else: "Two",
            unpermitted: "Ignored",
          },
        ),
        session: {},
        registration_journey: journey,
        registration_step: step,
      )

      wizard.store_current_step_answers

      expect(wizard.state_store.read.to_h.symbolize_keys).to eq(
        something: "One",
        something_else: "Two",
      )
    end
  end
end
