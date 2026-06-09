class FundingEligibility
  class MissingMandatoryInstitution < StandardError; end

  FUNDED_ELIGIBILITY_RESULT = :funded
  NOT_IN_ENGLAND = :not_in_england
  PREVIOUSLY_FUNDED = :previously_funded
  INELIGIBLE_SETTING = :ineligible_setting

  ELIGIBLE_NURSERY_TYPES = %w[
    local_authority_maintained_nursery
    preschool_class_as_part_of_school
  ].freeze

  FUNDING_STATUS_CODE_DESCRIPTIONS = {
    FUNDED_ELIGIBILITY_RESULT => "funding_details.scholarship_eligibility",
    NOT_IN_ENGLAND => "funding_details.inside_catchment",
    PREVIOUSLY_FUNDED => "funding_details.previously_funded",
    INELIGIBLE_SETTING => "funding_details.ineligible_setting",
  }.freeze

  attr_reader :institution,
              :course,
              :query_store

  delegate :work_setting,
           to: :query_store

  def initialize(institution:,
                 course:,
                 inside_catchment:,
                 query_store:,
                 **)
    @institution = institution
    @course = course
    @inside_catchment = inside_catchment
    @query_store = query_store
  end

  def funded?
    funding_eligiblity_status_code == FUNDED_ELIGIBILITY_RESULT
  end

  def previously_funded?
    accepted_applications.any?
  end

  def funding_eligiblity_status_code
    @funding_eligiblity_status_code ||= begin
      return NOT_IN_ENGLAND unless @inside_catchment
      return PREVIOUSLY_FUNDED if previously_funded?

      case work_setting
      when Institution::STATE_FUNDED_INSTITUTION then school_policy
      when *Questionnaires::WorkSetting::CHILDCARE_SETTINGS then childcare_policy
      when *Questionnaires::WorkSetting::SCHOOL_SETTINGS then school_policy
      else INELIGIBLE_SETTING
      end
    end
  end

  def get_description_for_funding_status
    key = FUNDING_STATUS_CODE_DESCRIPTIONS.fetch(funding_eligiblity_status_code)
    I18n.t(key, course_name: course.name).html_safe if key
  end

private

  def childcare_policy
    kind_of_nursery = query_store.store["kind_of_nursery"]

    return INELIGIBLE_SETTING unless mandatory_institution.eligible_establishment?
    return FUNDED_ELIGIBILITY_RESULT if kind_of_nursery.in?(ELIGIBLE_NURSERY_TYPES)

    INELIGIBLE_SETTING
  end

  def school_policy
    return INELIGIBLE_SETTING unless mandatory_institution.eligible_establishment?

    FUNDED_ELIGIBILITY_RESULT
  end

  def users
    return User.where(trn:) if trn.present?

    User.where(one_login_id:)
  end

  def trn
    query_store.current_user&.trn
  end

  def one_login_id
    query_store.current_user&.one_login_id
  end

  def accepted_applications
    @accepted_applications ||= begin
      application_ids = users.flat_map do |user|
        user.applications
            .has_been_accepted
            .eligible_for_funding
            .where(funded_place: [nil, true])
            .pluck(:id)
      end

      Application.where(id: application_ids)
    end
  end

  def mandatory_institution
    raise MissingMandatoryInstitution if institution.nil?

    institution
  end
end
