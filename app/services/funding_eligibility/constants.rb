module FundingEligibility
  module Constants
    ELIGIBLE_FOR_FUNDING = :eligible_for_funding
    NOT_IN_ENGLAND = :not_in_england
    PREVIOUSLY_FUNDED = :previously_funded
    INELIGIBLE_SETTING = :ineligible_setting

    FUNDING_STATUS_CODE_DESCRIPTIONS = {
      ELIGIBLE_FOR_FUNDING => "funding_details.scholarship_eligibility",
      NOT_IN_ENGLAND => "funding_details.inside_catchment",
      PREVIOUSLY_FUNDED => "funding_details.previously_funded",
      INELIGIBLE_SETTING => "funding_details.ineligible_setting",
    }.freeze
  end
end
