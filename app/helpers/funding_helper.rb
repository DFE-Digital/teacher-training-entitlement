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

    application.work_setting == "another_setting" && application.course.identifier != "npq-early-headship-coaching-offer"
  end

  def targeted_support_funding
    I18n.t("funding_details.targeted_funding_eligibility").html_safe
  end

private

  def funding_eligibility_calculator(application)
    FundingEligibility.new(
      course: application.course,
      institution: application.institution&.institutionable,
      inside_catchment: application.teacher_catchment == "england",
      trn: application.user.trn,
      get_an_identity_id: application.user.get_an_identity_id,
      query_store: query_store(application),
    )
  end

  def query_store(application)
    RegistrationQueryStore.new(store: application.raw_application_data)
  end
end
