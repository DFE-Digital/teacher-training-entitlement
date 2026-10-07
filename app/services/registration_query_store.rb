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

  def works_in_school?
    work_setting == Institution::STATE_FUNDED_INSTITUTION
  end

  def works_in_other?
    work_setting == Institution::OTHER
  end

  def course
    course_cohort.course
  end

  def course_cohort
    @course_cohort ||= CourseCohort.find_by(ecf_id: store["course_cohort_ecf_id"])
  end

  def lead_provider
    @lead_provider ||= LeadProvider.find_by(id: store["lead_provider_id"])
  end

  def date_of_birth
    store["date_of_birth"]
  end

  def work_setting
    store["work_setting"]
  end
end
