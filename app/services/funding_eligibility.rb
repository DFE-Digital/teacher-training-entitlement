class FundingEligibility
  class MissingMandatoryInstitution < StandardError; end

  FUNDED_ELIGIBILITY_RESULT = :funded
  NOT_IN_ENGLAND = :not_in_england
  PREVIOUSLY_FUNDED = :previously_funded
  INELIGIBLE_SETTING = :ineligible_setting
  MARKED_INELIGIBLE_BY_POLICY = :marked_ineligible_by_policy

  ELIGIBLE_NURSERY_TYPES = %w[
    local_authority_maintained_nursery
    preschool_class_as_part_of_school
  ].freeze

  # GIAS establishment type codes whose institutions can be funded.
  ELIGIBLE_ESTABLISHMENT_TYPE_CODES = {
    "1" => "Community school",
    "2" => "Voluntary aided school",
    "3" => "Voluntary controlled school",
    "5" => "Foundation school",
    "6" => "City technology college",
    "7" => "Community special school",
    "8" => "Non-maintained special school",
    "10" => "Other independent special school",
    "12" => "Foundation special school",
    "14" => "Pupil referral unit",
    "15" => "Local authority nursery school",
    "18" => "Further education",
    "24" => "Secure units",
    "26" => "Service children's education",
    "28" => "Academy sponsor led",
    "31" => "Sixth form centres",
    "32" => "Special post 16 institution",
    "33" => "Academy special sponsor led",
    "34" => "Academy converter",
    "35" => "Free schools",
    "36" => "Free schools special",
    "38" => "Free schools alternative provision",
    "39" => "Free schools 16 to 19",
    "40" => "University technical college",
    "41" => "Studio schools",
    "42" => "Academy alternative provision converter",
    "43" => "Academy alternative provision sponsor led",
    "44" => "Academy special converter",
    "45" => "Academy 16-19 converter",
    "46" => "Academy 16 to 19 sponsor led",
  }.freeze

  # institution_type slugs whose funding depends on the GIAS establishment type code.
  ESTABLISHMENT_TYPE_CODE_CHECKED_INSTITUTION_TYPES = [
    Institution::STATE_FUNDED,
    Institution::FURTHER_EDUCATION,
  ].freeze

  attr_reader :institution, :course, :query_store

  delegate :work_setting, to: :query_store

  def initialize(institution:, course:, query_store:)
    @institution = institution
    @course = course
    @query_store = query_store
  end

  def funded?
    funding_eligibility == FUNDED_ELIGIBILITY_RESULT
  end

  def previously_funded?
    accepted_applications.any?
  end

  def funding_eligibility
    @funding_eligibility ||= begin
      return NOT_IN_ENGLAND if @institution && !@institution.in_england?
      return PREVIOUSLY_FUNDED if previously_funded?

      case work_setting
      when Institution::STATE_FUNDED_INSTITUTION then school_policy
      else INELIGIBLE_SETTING
      end
    end
  end

private

  def school_policy
    return INELIGIBLE_SETTING unless eligible_establishment?(mandatory_institution)

    FUNDED_ELIGIBILITY_RESULT
  end

  def eligible_establishment?(institution)
    case institution.institution_type
    when Institution::LOCAL_AUTHORITY
      true
    when *ESTABLISHMENT_TYPE_CODE_CHECKED_INSTITUTION_TYPES
      ELIGIBLE_ESTABLISHMENT_TYPE_CODES.key?(institution.establishment_type_code)
    else
      false
    end
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
