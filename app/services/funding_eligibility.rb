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

  def initialize(institution:,
                 course:,
                 inside_catchment:,
                 user:,
                 work_setting:)
    @institution = institution
    @course = course
    @inside_catchment = inside_catchment
    @user = user
    @work_setting = work_setting
  end

  def eligible_for_funding?
    @institution.in_england? &&
      @institution.eligible_establishment? &&
      !previously_funded? &&
      funded?
  end

  def funded?
    funding_eligiblity_status_code == FUNDED_ELIGIBILITY_RESULT
  end

  def previously_funded?
    accepted_applications.any?
  end

  def funding_eligiblity_status_code
    @funding_eligiblity_status_code ||= if !@inside_catchment
                                          NOT_IN_ENGLAND
                                        elsif previously_funded?
                                          PREVIOUSLY_FUNDED
                                        elsif state_funded_eligible_setting?
                                          FUNDED_ELIGIBILITY_RESULT
                                        else
                                          INELIGIBLE_SETTING
                                        end
  end

  def get_description_for_funding_status
    key = FUNDING_STATUS_CODE_DESCRIPTIONS.fetch(funding_eligiblity_status_code)
    course_name = @course.localise_sentence_embedded_course_name

    I18n.t(key, course_name:).html_safe if key
  end

private

  def state_funded_eligible_setting?
    raise MissingMandatoryInstitution if @institution.nil? && state_funded_institution?

    state_funded_institution? &&
      @institution.eligible_establishment?
  end

  def state_funded_institution?
    @work_setting == Institution::STATE_FUNDED_INSTITUTION
  end

  def users
    return User.where(trn: @user.trn) if @user.trn.present?

    User.where(one_login_id: @user.one_login_id)
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
end
