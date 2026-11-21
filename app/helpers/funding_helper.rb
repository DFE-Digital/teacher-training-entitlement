module FundingHelper
  FUNDING_STATUS_COLOUR_MAP = {
    FundingEligibilities::FUNDED_ELIGIBILITY_RESULT => "green",
    FundingEligibilities::NOT_IN_ENGLAND => "red",
    FundingEligibilities::PREVIOUSLY_FUNDED => "red",
    FundingEligibilities::INELIGIBLE_SETTING => "red",
    FundingEligibilities::MARKED_INELIGIBLE_BY_POLICY => "red",
  }.freeze

  def targeted_support_funding
    I18n.t("funding_details.targeted_funding_eligibility").html_safe
  end

  def funding_status_colour(status)
    FUNDING_STATUS_COLOUR_MAP.fetch(status.to_s.to_sym, "grey")
  end

  def funding_status_badge(application)
    text = application.eligible_for_funding? ? "Eligible" : "Not eligible"
    govuk_tag(text:, colour: funding_status_colour(application.funding_eligibility))
  end
end
