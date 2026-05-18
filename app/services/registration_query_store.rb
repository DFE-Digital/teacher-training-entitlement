class RegistrationQueryStore
  attr_reader :store

  def initialize(store:)
    @store = store
  end

  def current_user
    store["current_user"] || User.find_by(id: store["current_user_id"])
  end

  def funding
    store["funding"]
  end

  def funding_amount
    store["funding_amount"]
  end

  def inside_catchment?
    store["teacher_catchment"] == "england"
  end

  def funding_eligiblity_status_code
    store["funding_eligiblity_status_code"]
  end

  def teacher_catchment_humanized
    case store["teacher_catchment"]
    when "another"
      "No"
    when "england"
      "Yes"
    end
  end

  def teacher_catchment_england?
    store["teacher_catchment"] == "england"
  end

  def valid_employent_type_for_england?
    teacher_catchment_england?
  end

  def works_in_other?
    store["work_setting"] == "other"
  end

  def has_ofsted_urn?
    store["has_ofsted_urn"] == "yes"
  end

  def course
    @course ||= Course.reception
  end

  def lead_provider
    @lead_provider ||= LeadProvider.find_by(id: store["lead_provider_id"])
  end

  def date_of_birth
    store["date_of_birth"]
  end

  def formatted_date_of_birth
    date_of_birth&.to_fs(:govuk)
  end

  def maths_understanding?
    store["maths_understanding"]
  end

  def work_setting
    store["work_setting"]
  end
end
