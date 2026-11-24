module Registrations
  class NpdFundingEligibilityResultsComponent < BaseCustomViewComponent
    def ineligible?
      result == Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING
    end

    def previously_funded?
      result == Registrations::FundingEligibilityConstants::PREVIOUSLY_FUNDED
    end

    def not_in_england?
      result == Registrations::FundingEligibilityConstants::NOT_IN_ENGLAND
    end

    def funded?
      result == Registrations::FundingEligibilityConstants::FUNDED
    end

    def eligibility_result_text
      case result
      when Registrations::FundingEligibilityConstants::NOT_IN_ENGLAND
        "You're not eligible because you're not in England"
      when Registrations::FundingEligibilityConstants::FUNDED
        "You're eligible for funding"
      when Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING
        "You're not eligible for scholarship funding because you do not work in an eligible setting"
      else
        raise ArgumentError, "Unsupported funding eligibility result: #{result.inspect}"
      end
    end

  private

    def result
      @wizard_step.state_store["funding_eligibility_result"]
    end
  end
end
