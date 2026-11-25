module Registrations
  module Spikes
    class FavouriteThingsFundingEligibility
      def initialize(wizard_step:)
        @wizard_step = wizard_step
      end

      def call
        wizard_step.state_store.write(funding_eligibility_result:)
      end

    private

      attr_reader :wizard_step

      def funding_eligibility_result
        return Registrations::FundingEligibilityConstants::FUNDED if likes_cats_and_cricket?

        Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING
      end

      def likes_cats_and_cricket?
        wizard_step.state_store["favourite_pet"] == "cat" &&
          wizard_step.state_store["favourite_sport"] == "cricket"
      end
    end
  end
end
