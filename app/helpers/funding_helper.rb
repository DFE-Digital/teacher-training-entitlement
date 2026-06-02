module FundingHelper
  FUNDING_STATUS_COLOUR_MAP = {
    FundingEligibility::FUNDED_ELIGIBILITY_RESULT => "green",
    FundingEligibility::NOT_IN_ENGLAND => "red",
    FundingEligibility::PREVIOUSLY_FUNDED => "red",
    FundingEligibility::INELIGIBLE_SETTING => "red",
  }.freeze

  def scholarship_funding_eligibility(application)
    funding_eligibility = funding_eligibility_calculator(application)

    funding_eligibility.get_description_for_funding_status
  end

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

  def funding_status_colour(status)
    FUNDING_STATUS_COLOUR_MAP.fetch(status.to_s.to_sym, "grey")
  end

  def funding_status_badge(application)
    text = "Not eligible"
    if application.funding_eligiblity_status_code.to_s == FundingEligibility::FUNDED_ELIGIBILITY_RESULT.to_s
      text = "Eligible"
    end
    govuk_tag(text:, colour: funding_status_colour(application.funding_eligiblity_status_code))
  end

private

  def funding_eligibility_calculator(application)
    FundingEligibility.new(
      course: application.course,
      institution: application.institution,
      inside_catchment: application.teacher_catchment == "england",
      query_store: RegistrationQueryStore.new(store: application.raw_application_data),
    )
  end
end
