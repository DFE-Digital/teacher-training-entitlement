class RegistrationQueryStore
  attr_reader :store

  def initialize(store:)
    @store = store
  end

  def current_user
    store["current_user"] || User.find_by(id: store["current_user_id"])
  end

  def trn_set_via_fallback_verification_question?
    store["trn_set_via_fallback_verification_question"]
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

  def works_in_school?
    store["works_in_school"] == "yes"
  end

  def works_in_childcare?
    store["works_in_childcare"] == "yes"
  end

  def works_in_another_setting?
    store["work_setting"] == "another_setting"
  end

  def works_in_other?
    store["work_setting"] == "other"
  end

  def has_ofsted_urn?
    store["has_ofsted_urn"] == "yes"
  end

  def referred_by_return_to_teaching_adviser?
    store["referred_by_return_to_teaching_adviser"] == "yes"
  end

  def kind_of_nursery_public?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(store["kind_of_nursery"])
  end

  def kind_of_nursery_private?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(store["kind_of_nursery"])
  end

  def course
    if Rails.env.production?
      @course ||= Course.first
      return @course
    end
    @course ||= Course.reception
  end

  def course_cohort
    if Rails.env.production?
      @course_cohort = CourseCohort.first
    end

    return @course_cohort if @course_cohort

    course_cohort = if store["course_cohort_id"].blank?
                      assign_course_cohort
                    else
                      CourseCohort.find_by(id: store["course_cohort_id"])
                    end
    @course_cohort = course_cohort if course_cohort.present?
  end

  def assign_course_cohort
    return if course.nil?

    CourseCohort.next_open_for(course:).tap do |course_cohort|
      store["course_cohort_id"] = course_cohort.id if course_cohort
    end
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

  def childminder?
    store["kind_of_nursery"] == "childminder"
  end

  def work_setting
    store["work_setting"]
  end
end
