class Application < ApplicationRecord
  UK_CATCHMENT_AREA = %w[jersey_guernsey_isle_of_man england northern_ireland scotland wales].freeze
  INELIGIBLE_FOR_FUNDING_REASONS = %w[
    previously-funded
    establishment-ineligible
  ].freeze

  has_paper_trail meta: { note: :version_note }

  belongs_to :user
  belongs_to :course_cohort
  belongs_to :lead_provider
  belongs_to :institution, optional: true

  has_one :course, through: :course_cohort
  has_one :cohort, through: :course_cohort
  has_one :schedule, through: :course_cohort

  # Convenience methods to access the institutionable through institution
  # Rails delegated_type provides #school, #private_childcare_provider, #local_authority on Institution
  delegate :school, :private_childcare_provider, :local_authority, to: :institution, allow_nil: true

  def private_childcare_provider_including_disabled
    return nil unless institution&.private_childcare_provider?

    PrivateChildcareProvider.including_disabled.find_by(id: institution.institutionable_id)
  end

  has_many :participant_id_changes, through: :user
  has_many :application_states
  has_many :declarations

  scope :expired_applications, -> { where(status: [REJECTED, WITHDRAWN]).where("created_at < ?", cut_off_date_for_expired_applications) }
  scope :active_applications, -> { where.not(id: expired_applications) }
  scope :accepted, -> { where(status: ACCEPTED) }
  scope :eligible_for_funding, -> { where(eligible_for_funding: true) }
  scope :for_manual_review, -> { where.not(review_status: nil) }
  scope :not_withdrawn, -> { where.not(status: WITHDRAWN).or(where(status: nil)) }
  scope :not_rejected, -> { where.not(status: REJECTED) }
  scope :accepted_or_withdrawn_or_deferred, -> { where(status: [ACCEPTED, WITHDRAWN, DEFERRED]) }
  scope :started_or_accepted_or_withdrawn_or_deferred, -> { where(status: [STARTED, ACCEPTED, WITHDRAWN, DEFERRED]) }

  attr_accessor :version_note, :skip_touch_user_if_changed

  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :user_id,
            uniqueness: {
              scope: :course_cohort_id,
              conditions: -> { where.not(status: REJECTED) },
            }, unless: :provider_rejected?
  validate :ensure_change_status, if: -> { will_save_change_to_status? && persisted? }
  validate :ensure_valid_status_transition, if: -> { status_changed? }
  validates :funded_place, inclusion: { in: [true, false] }, if: :validate_funded_place?
  validate :funded_place_nil_for_cohort_with_ineligible_for_funding_cap
  validate :eligible_for_funded_place

  after_commit :touch_user_if_changed

  API_STATUSES = [].freeze

  STATUSES =
    [
      PENDING = "pending".freeze,
      ACCEPTED = "accepted".freeze,
      STARTED = "started".freeze,
      COMPLETED = "completed".freeze,
      DEFERRED = "deferred".freeze,
      WITHDRAWN = "withdrawn".freeze,
      REJECTED = "rejected".freeze,
    ].freeze

  STATUS_TRANSITIONS = {
    nil => [PENDING].freeze,
    PENDING => [ACCEPTED, REJECTED].freeze,
    ACCEPTED => [STARTED, COMPLETED].freeze,
    STARTED => [COMPLETED, DEFERRED, WITHDRAWN].freeze,
    DEFERRED => [STARTED].freeze,
    WITHDRAWN => [STARTED].freeze,
    REJECTED => [PENDING].freeze,
  }.freeze

  enum :status,
       STATUSES.index_with(&:itself),
       suffix: true

  enum :kind_of_nursery, {
    local_authority_maintained_nursery: "local_authority_maintained_nursery",
    preschool_class_as_part_of_school: "preschool_class_as_part_of_school",
    private_nursery: "private_nursery",
    another_early_years_setting: "another_early_years_setting",
    childminder: "childminder",
  }, suffix: true

  enum :funding_choice, {
    school: "school",
    trust: "trust",
    self: "self",
    another: "another",
    employer: "employer",
  }, suffix: true

  enum :reason_for_rejection, {
    registration_expired: "registration_expired",
    rejected_by_provider: "rejected_by_provider",
    other_application_in_this_cohort_accepted: "other_application_in_this_cohort_accepted",
  }, suffix: true

  enum :review_status, {
    "Needs review" => "needs_review",
    "Awaiting information" => "awaiting_information",
    "Re-register" => "reregister",
    "Decision made" => "decision_made",
  }, suffix: true

  validates :funded_place, inclusion: { in: [true, false] }, if: :validate_funded_place?
  validate :funded_place_nil_for_cohort_with_ineligible_for_funding_cap
  validate :eligible_for_funded_place

  def can_change_provider?
    pending_status?
  end

  def can_transition_to?(new_status)
    STATUS_TRANSITIONS[status]&.include?(new_status.to_s)
  end

  # `eligible_for_dfe_funding?`  takes into consideration what we know
  # about user eligibility plus if it has been previously funded. We need
  # to keep this method in place to keep consistency during the split between
  # ECF and NPQ. In the mid term we will perform this calculation on NPQ and
  # store the value in the `eligible_for_funding` attribute.
  def eligible_for_dfe_funding?(with_funded_place: false)
    if previously_funded? && funding_eligiblity_status_code != "marked_funded_by_policy"
      false
    else
      funding_eligibility(with_funded_place:)
    end
  end

  def has_been_accepted?
    !status.to_s.in?([PENDING, REJECTED])
  end

  def previously_funded?
    # This is an optimization used by the API Applications::Query in order
    # to speed up the bulk-retrieval of Applications.
    return transient_previously_funded if respond_to?(:transient_previously_funded)

    @previously_funded ||= user.applications
      .where.not(id:)
      .accepted
      .eligible_for_funding
      .where(funded_place: [nil, true])
      .exists?
  end

  def provider_rejected?
    rejected_status?
  end

  def ineligible_for_funding_reason
    return "previously-funded" if previously_funded?

    "establishment-ineligible" unless eligible_for_funding
  end

  def private_nursery?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(kind_of_nursery)
  end

  def public_nursery?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(kind_of_nursery)
  end

  def inside_uk_catchment?
    teacher_catchment.in?(UK_CATCHMENT_AREA)
  end

  def inside_catchment?
    %w[england].include?(teacher_catchment) || (cohort.start_year < 2024 && !!school&.urn&.starts_with?("1"))
  end

  def employer_name_to_display
    institution&.name || ""
  end

  def long_employer_name_to_display
    institution&.name_with_address || ""
  end

  def employer_urn
    institution&.urn || ""
  end

  def school_urn
    school&.urn
  end

  def get_approval_status
    case status
    when ACCEPTED then REJECTED
    when REJECTED then PENDING
    else ACCEPTED
    end
  end

  def get_participant_outcome_state
    case participant_outcome_state
    when "passed" then "failed"
    else "passed"
    end
  end

  def self.cut_off_date_for_expired_applications
    Time.zone.local(2024, 6, 30)
  end

  def fundable?
    eligible_for_dfe_funding?(with_funded_place: true)
  end

  def latest_participant_outcome_state
    declarations.completed.billable_or_voidable.latest_first.first&.participant_outcomes&.latest&.state
  end

  def lookup_state_change_reason(changed_at:, changed_status:)
    variance = 0.5
    application_states.find { |application_state|
      application_state.created_at >= changed_at - variance &&
        application_state.created_at <= changed_at + variance &&
        application_state.status == changed_status
    }&.reason
  end

  def update_status!(status:, reason:, admin_user:, **additional_attributes)
    valid_transition = can_transition_to?(status)
    if !valid_transition && admin_user.nil?
      raise StandardError, "Admin user must be provided"
    end

    application_states.create!(status:, reason:)
    assign_attributes(additional_attributes.merge(status:))
    save!(validate: valid_transition)
  end

private

  def ensure_valid_status_transition
    from, to = changes[:status]
    return if from.nil? # allow setting initial status

    if STATUS_TRANSITIONS.fetch(from, []).exclude?(to)
      errors.add(:status, :invalid_status_transition, from: from || "blank", to:)
    end
  end

  def ensure_change_status
    if accepted_status? && declarations.blank? && deferred_status?
      errors.add(:status, :invalid_deferral_no_declarations)
    end
  end

  def funding_eligibility(with_funded_place:)
    return eligible_for_funding unless with_funded_place

    eligible_for_funding && (funded_place.nil? || funded_place)
  end

  def validate_funded_place?
    accepted_status? && errors.blank? && cohort&.funding_cap?
  end

  def funded_place_nil_for_cohort_with_ineligible_for_funding_cap
    if accepted_status? && errors.blank? && !cohort&.funding_cap? && !funded_place.nil?
      errors.add(:funded_place, :should_not_be_set)
    end
  end

  def eligible_for_funded_place
    return if errors.any?
    return unless cohort&.funding_cap?

    if funded_place && !eligible_for_funding
      errors.add(:funded_place, :not_eligible)
    end
  end

  def touch_user_if_changed
    return if skip_touch_user_if_changed
    return unless saved_change_to_status?

    user.touch(time: updated_at)
  end
end
