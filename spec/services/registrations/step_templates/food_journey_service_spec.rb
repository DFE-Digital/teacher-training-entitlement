require "rails_helper"

RSpec.describe Registrations::StepTemplates::FoodJourneyService do
  describe "#call" do
    it "creates the complicated food journey steps" do
      journey = RegistrationJourney.create!(name: "Food journey", slug: "food-journey")

      expect {
        described_class.new(registration_journey: journey, registration_template: nil).call
      }.to change(journey.registration_steps, :count).by(14)

      expect(journey.registration_steps.order(:order).pluck(:slug)).to eq(%w[
        meal-kind
        food-mood
        comfort-main
        comfort-side
        comfort-pudding
        fresh-main
        fresh-extras
        fresh-drink
        spicy-main
        spice-level
        cooling-side
        dietary-requirements
        funding-eligibility-results
        check-answers
      ])
    end

    it "sets the branch choices on the food mood step" do
      journey = RegistrationJourney.create!(name: "Food journey", slug: "food-journey")

      described_class.new(registration_journey: journey, registration_template: nil).call

      food_mood = journey.registration_steps.find_by!(slug: "food-mood")
      comfort_main = journey.registration_steps.find_by!(slug: "comfort-main")
      fresh_main = journey.registration_steps.find_by!(slug: "fresh-main")
      spicy_main = journey.registration_steps.find_by!(slug: "spicy-main")

      expect(food_mood.answer_data).to eq([
        { "name" => "Comfort food", "value" => "comfort_food", "next_step_id" => comfort_main.id },
        { "name" => "Fresh and light", "value" => "fresh_and_light", "next_step_id" => fresh_main.id },
        { "name" => "Spicy and bold", "value" => "spicy_and_bold", "next_step_id" => spicy_main.id },
      ])
    end

    it "sets values for answer choices" do
      journey = RegistrationJourney.create!(name: "Food journey", slug: "food-journey")

      described_class.new(registration_journey: journey, registration_template: nil).call

      meal_kind = journey.registration_steps.find_by!(slug: "meal-kind")

      expect(meal_kind.answer_data).to eq([
        { "name" => "Breakfast", "value" => "breakfast" },
        { "name" => "Lunch", "value" => "lunch" },
        { "name" => "Dinner", "value" => "dinner" },
      ])
    end

    it "sets previous step ids for branch steps" do
      journey = RegistrationJourney.create!(name: "Food journey", slug: "food-journey")

      described_class.new(registration_journey: journey, registration_template: nil).call

      food_mood = journey.registration_steps.find_by!(slug: "food-mood")
      comfort_main = journey.registration_steps.find_by!(slug: "comfort-main")
      comfort_side = journey.registration_steps.find_by!(slug: "comfort-side")

      expect(food_mood.previous_step_id).to eq(journey.registration_steps.find_by!(slug: "meal-kind").id)
      expect(comfort_main.previous_step_id).to eq(food_mood.id)
      expect(comfort_side.previous_step_id).to eq(comfort_main.id)
    end

    it "adds a funding eligibility results step" do
      journey = RegistrationJourney.create!(name: "Food journey", slug: "food-journey")

      described_class.new(registration_journey: journey, registration_template: nil).call

      funding_eligibility = journey.registration_steps.find_by!(slug: "funding-eligibility-results")

      expect(funding_eligibility).to have_attributes(
        name: "Funding eligibility results",
        type: "Custom view",
        order: 13,
      )
      expect(funding_eligibility.custom_view_class_name)
        .to eq("Registrations::ComplicatedFoodFundingEligibilityResultsComponent")
      expect(funding_eligibility.services_to_run(execute_point: :before_show))
        .to eq(["Registrations::FundingEligibility::FoodFundingEligibilityService"])
    end
  end
end
