module Registrations
  module Steps
    module ExcellenceInReception
      class PossibleFunding
        include DfE::Wizard::Step

        TITLE = "Funding eligibility result".freeze
        PARTIAL = "html_partial".freeze
        PARTIAL_NAME = "registrations/shared/funding_eligibility_result".freeze
        DISPLAY_ON_CHECK_ANSWERS = false

        def self.permitted_params = []
      end
    end
  end
end
