module Registrations
  module Steps
    module SharedFavouritePetAndSport
      class FundingEligibilityResult
        include DfE::Wizard::Step

        TITLE = "Funding eligibility result".freeze
        PARTIAL = "html_partial".freeze
        PARTIAL_NAME = "registrations/shared/funding_eligibility_result".freeze

        def self.permitted_params = []
      end
    end
  end
end
