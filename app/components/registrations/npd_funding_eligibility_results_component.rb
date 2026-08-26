module Registrations
  class NpdFundingEligibilityResultsComponent < BaseCustomViewComponent
    def ineligible?
      @wizard.state_store["funding_eligibility_result"] == "ineligible"
    end
  end
end
