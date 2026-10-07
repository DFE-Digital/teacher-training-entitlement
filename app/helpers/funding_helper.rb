module FundingHelper
  FUNDING_STATUS_COLOUR_MAP = {
    FundingEligibility::Constants::ELIGIBLE_FOR_FUNDING => "green",
    FundingEligibility::Constants::NOT_IN_ENGLAND => "red",
    FundingEligibility::Constants::PREVIOUSLY_FUNDED => "red",
    FundingEligibility::Constants::INELIGIBLE_SETTING => "red",
  }.freeze

  def scholarship_eligibility_in_review?(application)
    return false if application.eligible_for_funding
    return false if !application.eligible_for_funding && application.funding_choice.present?
    return false unless application.inside_catchment?
    return true if application.referred_by_return_to_teaching_adviser == "yes"

    application.work_setting == "another_setting"
  end

  def targeted_support_funding
    I18n.t("funding_details.targeted_funding_eligibility").html_safe
  end

  def scholarship_funding_eligibility(application)
    status_code = if application.previously_funded?
                    FundingEligibility::Constants::PREVIOUSLY_FUNDED
                  else
                    application.funding_eligiblity_status_code.to_s.to_sym
                  end

    key = FundingEligibility::Constants::FUNDING_STATUS_CODE_DESCRIPTIONS[status_code]
    return "" if key.nil?

    I18n.t(key, course_name: application.course.name).html_safe
  end

  def funding_status_colour(status)
    FUNDING_STATUS_COLOUR_MAP.fetch(status.to_s.to_sym, "grey")
  end

  def funding_status_badge(application)
    text = "Not eligible"
    if application.funding_eligiblity_status_code.to_s == FundingEligibility::Constants::ELIGIBLE_FOR_FUNDING.to_s
      text = "Eligible"
    end
    govuk_tag(text:, colour: funding_status_colour(application.funding_eligiblity_status_code))
  end
end
