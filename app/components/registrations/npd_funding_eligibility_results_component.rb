module Registrations
  class NpdFundingEligibilityResultsComponent < BaseCustomViewComponent
    def ineligible?
      result == Registrations::ExcellenceInReception::FundingEligibility::INELIGIBLE_SETTING
    end

    def previously_funded?
      result == Registrations::ExcellenceInReception::FundingEligibility::PREVIOUSLY_FUNDED
    end

    def not_in_england?
      result == Registrations::ExcellenceInReception::FundingEligibility::NOT_IN_ENGLAND
    end

    def funded?
      result == Registrations::ExcellenceInReception::FundingEligibility::FUNDED
    end

    def eligibility_result_text
      case result
      when Registrations::ExcellenceInReception::FundingEligibility::NOT_IN_ENGLAND
        "You're not eligible because you're not in England"
      when Registrations::ExcellenceInReception::FundingEligibility::FUNDED
        "You're eligible for funding"
      when Registrations::ExcellenceInReception::FundingEligibility::INELIGIBLE_SETTING
        "You're not eligible for scholarship funding because you do not work in an eligible setting"
      else
        raise ArgumentError, "Unsupported funding eligibility result: #{result.inspect}"
      end
    end

  private

    def result
      @router_step.state_store["funding_eligibility_result"]
    end
  end
end
