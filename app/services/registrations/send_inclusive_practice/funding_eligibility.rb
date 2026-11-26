module Registrations
  module SendInclusivePractice
    class FundingEligibility
      def initialize(wizard_step:)
        @wizard_step = wizard_step
      end

      def call
        wizard_step.state_store.write(funding_eligibility_result:)
      end

    private

      attr_reader :wizard_step

      def funding_eligibility_result
        return Registrations::FundingEligibilityConstants::FUNDED if eligible_for_funding?

        Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING
      end

      def eligible_for_funding?
        state_store["state_funded_school"] == "yes" &&
          state_store["teaches_children_with_send_needs"] == "yes"
      end

      def state_store
        wizard_step.state_store
      end
    end
  end
end
