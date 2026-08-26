module Registrations
  module StepTemplates
    class FoodJourneyService < BaseStepTemplateService
      def call
        meal_kind = create_step(
          name: "What kind of meal are you planning?",
          slug: "meal-kind",
          type: "Radio buttons",
          order: 1,
          answers: [
            { "name" => "Breakfast" },
            { "name" => "Lunch" },
            { "name" => "Dinner" },
          ],
        )

        food_mood = create_step(
          name: "Which food mood are you in?",
          slug: "food-mood",
          type: "Radio buttons",
          order: 2,
          previous_step_id: meal_kind.id,
          answers: [
            { "name" => "Comfort food" },
            { "name" => "Fresh and light" },
            { "name" => "Spicy and bold" },
          ],
        )

        comfort_main = create_step(
          name: "[Comfort branch 1/3] Which cosy main sounds best?",
          slug: "comfort-main",
          type: "Radio buttons",
          order: 3,
          previous_step_id: food_mood.id,
          answers: [
            { "name" => "Macaroni cheese" },
            { "name" => "Pie and mash" },
            { "name" => "Baked potato" },
          ],
        )

        comfort_side = create_step(
          name: "[Comfort branch 2/3] Choose your comfort side",
          slug: "comfort-side",
          type: "Checkboxes",
          order: 4,
          previous_step_id: comfort_main.id,
          answers: [
            { "name" => "Garlic bread" },
            { "name" => "Roasted carrots" },
            { "name" => "Buttered greens" },
          ],
        )

        create_step(
          name: "[Comfort branch 3/3] Pick a comfort pudding",
          slug: "comfort-pudding",
          type: "Radio buttons",
          order: 5,
          previous_step_id: comfort_side.id,
          answers: [
            { "name" => "Apple crumble" },
            { "name" => "Sticky toffee pudding" },
            { "name" => "Rice pudding" },
          ],
        )

        fresh_main = create_step(
          name: "[Fresh branch 1/3] Which fresh main sounds best?",
          slug: "fresh-main",
          type: "Radio buttons",
          order: 6,
          previous_step_id: food_mood.id,
          answers: [
            { "name" => "Greek salad" },
            { "name" => "Sushi bowl" },
            { "name" => "Lemon herb chicken" },
          ],
        )

        fresh_extras = create_step(
          name: "[Fresh branch 2/3] Choose your fresh extras",
          slug: "fresh-extras",
          type: "Checkboxes",
          order: 7,
          previous_step_id: fresh_main.id,
          answers: [
            { "name" => "Avocado" },
            { "name" => "Pickled onions" },
            { "name" => "Toasted seeds" },
          ],
        )

        create_step(
          name: "[Fresh branch 3/3] Pick a fresh drink",
          slug: "fresh-drink",
          type: "Radio buttons",
          order: 8,
          previous_step_id: fresh_extras.id,
          answers: [
            { "name" => "Mint lemonade" },
            { "name" => "Iced green tea" },
            { "name" => "Sparkling water" },
          ],
        )

        spicy_main = create_step(
          name: "[Spicy branch 1/3] Which spicy main sounds best?",
          slug: "spicy-main",
          type: "Radio buttons",
          order: 9,
          previous_step_id: food_mood.id,
          answers: [
            { "name" => "Chilli paneer" },
            { "name" => "Jerk chicken" },
            { "name" => "Thai red curry" },
          ],
        )

        spice_level = create_step(
          name: "[Spicy branch 2/3] Choose your spice level",
          slug: "spice-level",
          type: "Radio buttons",
          order: 10,
          previous_step_id: spicy_main.id,
          answers: [
            { "name" => "Gentle warmth" },
            { "name" => "Proper kick" },
            { "name" => "Regret tomorrow" },
          ],
        )

        create_step(
          name: "[Spicy branch 3/3] Pick a cooling side",
          slug: "cooling-side",
          type: "Checkboxes",
          order: 11,
          previous_step_id: spice_level.id,
          answers: [
            { "name" => "Raita" },
            { "name" => "Cucumber salad" },
            { "name" => "Coconut rice" },
          ],
        )

        create_step(
          name: "Any dietary requirements?",
          slug: "dietary-requirements",
          type: "Checkboxes",
          order: 12,
          answers: [
            { "name" => "Vegetarian" },
            { "name" => "Vegan" },
            { "name" => "Gluten free" },
            { "name" => "Nut allergy" },
          ],
        )

        funding_eligibility = create_step(
          name: "Funding eligibility results",
          slug: "funding-eligibility-results",
          type: RegistrationSteps::CustomView::TYPE,
          order: 13,
        )
        funding_eligibility.set_custom_view!(
          custom_view_class_name: "Registrations::ComplicatedFoodFundingEligibilityResultsComponent",
        )
        funding_eligibility.add_service!(
          class_name: "Registrations::FundingEligibility::FoodFundingEligibilityService",
          execute_point: :before_show,
        )

        create_step(
          name: "Check answers",
          slug: "check-answers",
          type: "Check answers",
          order: 14,
        )

        food_mood.set_answers!(
          answers: [
            { "name" => "Comfort food", "next_step_id" => comfort_main.id },
            { "name" => "Fresh and light", "next_step_id" => fresh_main.id },
            { "name" => "Spicy and bold", "next_step_id" => spicy_main.id },
          ],
        )
      end

    private

      def create_step(name:, slug:, type:, order:, answers: [], previous_step_id: nil)
        type_as_param = type.underscore.parameterize.underscore
        config = {
          type_as_param => {
            "answers" => answers,
          },
        }
        config["previous_step_id"] = previous_step_id if previous_step_id

        registration_journey.registration_steps.create!(
          name:,
          slug:,
          type:,
          order:,
          config:,
        )
      end
    end
  end
end
