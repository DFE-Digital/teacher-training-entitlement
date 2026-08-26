module Registrations
  module FundingEligibility
    class FoodFundingEligibilityService < Registrations::BaseStepService
      FUNDED_FOOD_MOOD = "fresh_and_light".freeze

      def call
        wizard.state_store.write(
          complicated_food_funding_eligible: funded?,
          complicated_food_funding_eligibility_result:,
        )
      end

    private

      def funded?
        @funded ||= wizard.state_store[:which_food_mood_are_you_in] == FUNDED_FOOD_MOOD
      end

      def complicated_food_funding_eligibility_result
        if funded?
          "You're eligible for funding, yay!"
        else
          "Sorry, but funding is only available for people that like 'Fresh and light' !"
        end
      end
    end
  end
end
