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

  attr_reader :institution,
              :course,
              :query_store

  delegate :work_setting,
           to: :query_store

  def initialize(institution:,
                 course:,
                 inside_catchment:, # rubocop:disable Lint/UnusedMethodArgument
                 query_store:,
                 **)
    @institution = institution
    @course = course
    # catchment determined from institution
    # @inside_catchment = inside_catchment
    @inside_catchment = nil
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
