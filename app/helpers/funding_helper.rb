module FundingHelper
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

private

  def funding_eligibility_calculator(application)
    FundingEligibility.new(
      course: application.course,
      institution: application.institution,
      inside_catchment: application.teacher_catchment == "england",
      user: application.user,
      work_setting: application.raw_application_data["work_setting"],
    )
  end
end
