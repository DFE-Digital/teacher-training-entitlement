module Registrations
  module JourneyStepTypes
    class FundingEligibilityResult < Registrations::JourneyStep
      TYPE_AS_PARAM = "funding_eligibility_result".freeze

      def self.permitted_params = %i[answer]
    end
  end
end
