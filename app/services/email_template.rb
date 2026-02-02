class EmailTemplate
  def self.call(data:)
    new(data:).call
  end

  attr_reader :data

  def initialize(data:)
    @data = data.with_indifferent_access
  end

  def call
    email_key
  end

private

  def email_key
    return :not_england_wrong_catchment if not_in_england?

    if eligible_for_funding?
      return :eligible_scholarship_funding if targeted_delivery_funding_eligibility?

      return :eligible_scholarship_funding_not_tsf
    end

    if previously_funded?
      return :not_eligible_scholarship_funding if targeted_delivery_funding_eligibility?

      return :already_funded_not_eligible_scholarship_funding_not_tsf
    end

    return :not_eligible_scholarship_funding_not_tsf if !eligible_for_funding? && !targeted_delivery_funding_eligibility?

    # Should not get called but left here as edge case if default ever needed
    :default
  end

  def ofsted_register?
    data["has_ofsted_urn"] == "yes"
  end

  def previously_funded?
    funding_eligiblity_status_code == FundingEligibility::PREVIOUSLY_FUNDED
  end

  def not_in_england?
    funding_eligiblity_status_code == FundingEligibility::NOT_IN_ENGLAND
  end

  def eligible_for_funding?
    funding_eligiblity_status_code == FundingEligibility::FUNDED_ELIGIBILITY_RESULT
  end

  def course
    Course.find_by(identifier: data["course_identifier"])
  end

  def funding_eligiblity_status_code
    data["funding_eligiblity_status_code"]
  end

  def targeted_delivery_funding_eligibility?
    data["targeted_delivery_funding_eligibility"]
  end
end
