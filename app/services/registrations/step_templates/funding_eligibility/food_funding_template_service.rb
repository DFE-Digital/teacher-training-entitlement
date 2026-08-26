module Registrations
  module StepTemplates
    module FundingEligibility
      class FoodFundingTemplateService < BaseStepTemplateService
        def call
          food_mood = create_step(
            name: "Which food mood are you in?",
            slug: "food-mood",
            type: "Radio buttons",
            order: 1,
            answer_key: "which_food_mood_are_you_in",
            answers: [
              { "name" => "Fresh and light", "value" => "Fresh and light" },
              { "name" => "Comfort food", "value" => "Comfort food" },
            ],
          )

          funding_eligibility_results = create_step(
            name: "Funding eligibility results",
            slug: "funding-eligibility-results",
            type: RegistrationSteps::CustomView::TYPE,
            order: 2,
            previous_step_id: food_mood.id,
          )
          funding_eligibility_results.set_custom_view!(
            custom_view_class_name: "Registrations::ComplicatedFoodFundingEligibilityResultsComponent",
          )
          funding_eligibility_results.add_service!(
            class_name: "Registrations::FundingEligibility::FoodFundingEligibilityService",
            execute_point: :before_show,
          )

          create_step(
            name: "Check answers",
            slug: "check-answers",
            type: "Check answers",
            order: 3,
            previous_step_id: funding_eligibility_results.id,
          )
        end

      private

        def create_step(name:, slug:, type:, order:, answer_key: nil, answers: [], previous_step_id: nil)
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
            answer_key:,
            config:,
          )
        end
      end
    end
  end
end
