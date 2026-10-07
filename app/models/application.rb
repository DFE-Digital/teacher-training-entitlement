class Application < ApplicationRecord
  include EcfIdable
  UK_CATCHMENT_AREA = %w[jersey_guernsey_isle_of_man england northern_ireland scotland wales].freeze
  INELIGIBLE_FOR_FUNDING_REASONS = %w[
    previously-funded
    establishment-ineligible
  ].freeze

  has_paper_trail meta: { note: :version_note }

  belongs_to :user
  belongs_to :course_cohort
  belongs_to :institution, optional: true

  has_one :course, through: :course_cohort
  has_one :cohort, through: :course_cohort
  has_many :milestones, through: :course_cohort

  # Convenience methods to access the institutionable through institution
  # Rails delegated_type provides #school, #private_childcare_provider, #local_authority on Institution
  delegate :school, :private_childcare_provider, :local_authority, to: :institution, allow_nil: true

  has_many :participant_id_changes, through: :user
  has_many :application_events
  has_many :state_changes
  has_many :notifications
  has_many :declarations
  has_many :application_lead_providers

  has_one :deferred_event, -> { where(event: DEFERRED).order(created_at: :desc) }, class_name: "StateChange"
  has_one :rejected_event, -> { where(event: REJECTED).order(created_at: :desc) }, class_name: "StateChange"
  has_one :withdrawn_event, -> { where(event: WITHDRAWN).order(created_at: :desc) }, class_name: "StateChange"
  has_one :current_application_lead_provider,
          -> { where(current: true) }, class_name: "ApplicationLeadProvider"
  has_one :lead_provider, through: :current_application_lead_provider
  has_one :previous_application_lead_provider, -> { where(current: false).order(created_at: :desc) }, class_name: "ApplicationLeadProvider"
  has_one :previous_provider, through: :previous_application_lead_provider, source: :lead_provider
  has_one :started_declaration, -> { billable_or_changeable.where(declaration_type: Milestone::STARTED) }, class_name: "Declaration"
  has_one :completed_declaration, -> { billable_or_changable.where(declaration_type: Milestone::COMPLETED) }, class_name: "Declaration"

  scope :active_applications, -> { not_withdrawn }
  scope :has_been_accepted, -> { where(status: [ACCEPTED, STARTED, COMPLETED, DEFERRED, WITHDRAWN]) }
  scope :eligible_for_funding, -> { where(eligible_for_funding: true) }
  scope :not_withdrawn, -> { where.not(status: WITHDRAWN).or(where(status: nil)) }
  scope :not_rejected, -> { where.not(status: REJECTED) }
  scope :previous_valid_applications, -> { where(status: [PENDING, ACCEPTED, STARTED, DEFERRED]) }

  attr_accessor :version_note, :admin_user, :assignment

  validates :ecf_id, uniqueness: { case_sensitive: false }

  validates :user_id,
            uniqueness: {
              scope: :course_cohort_id,
              conditions: -> { where.not(status: [REJECTED]) },
              message: "/ Course Cohort already exists for user",
            }, unless: -> { rejected_status? }

  validate :ensure_valid_status_transition, if: -> { status_changed? && not_admin_user? }
  validates :funded_place, inclusion: { in: [true, false] }, if: :validate_funded_place?
  validate :funded_place_nil_for_cohort_with_ineligible_for_funding_cap
  validate :eligible_for_funded_place

  before_save :set_training_starts_at_from_course_cohort, if: :will_save_change_to_course_cohort_id?

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

  API_STATUSES = STATUSES + [REASSIGNED = "reassigned".freeze].freeze

  # status transitions details
  # nil       -> pending   ; application creation
  # pending   -> accepted  ; lead provider accepts application
  # pending   -> rejected  ; lead provider rejects application
  # accepted  -> started   ; lead provider sends started declaration
  # accepted  -> pending   ; lead provider resets application to pending
  # started   -> completed ; lead provider sends completed declaration
  # started   -> deferred  ; lead provider defers application
  # started   -> withdraw  ; lead provider withdraws application
  # started   -> accepted  ; lead provider voids started declaration
  # deferred  -> started   ; lead provider resumes application
  # deferred  -> withdrawn ; cron job ExpireDeferredApplication
  # rejected  -> pending   ; admin console `revert pending` action
  # completed -> started   ; lead provider voids completed declaration
  #
  STATUS_TRANSITIONS = {
    nil => [PENDING].freeze,
    PENDING => [ACCEPTED, REJECTED].freeze,
    ACCEPTED => [STARTED, PENDING].freeze,
    STARTED => [COMPLETED, DEFERRED, WITHDRAWN, ACCEPTED].freeze,
    DEFERRED => [STARTED, WITHDRAWN].freeze,
    REJECTED => [PENDING].freeze,
    COMPLETED => [STARTED].freeze,
  }.freeze

  enum :status,
       STATUSES.index_with(&:itself),
       suffix: true

  enum :funding_choice, {
    school: "school",
    trust: "trust",
    self: "self",
    another: "another",
    employer: "employer",
  }, suffix: true

  validates :funded_place, inclusion: { in: [true, false] }, if: :validate_funded_place?
  validate :funded_place_nil_for_cohort_with_ineligible_for_funding_cap
  validate :eligible_for_funded_place

  def contract
    return unless course_cohort && lead_provider

    course_cohort.contract(lead_provider:)
  end

  def lead_provider=(new_provider)
    change_provider!(to: new_provider)
  end

  def change_provider!(to:)
    return if to == lead_provider

    timestamp = Time.zone.now
    application_lead_providers.current.update_all(
      current: false,
      updated_at: timestamp,
      unassigned_at: timestamp,
    )
    application_lead_providers.create!(
      lead_provider: to,
      current: true,
      assigned_at: timestamp,
    )
    touch_later
  end

  def assigned_at
    # assignment is a specific a application_lead_provider record set before render
    assignment&.assigned_at
  end

  def unassigned_at
    # assignment is a specific a application_lead_provider record set before render
    assignment&.unassigned_at
  end

  def can_change_provider?
    pending_status? || rejected_status?
  end

  def can_transition_to?(new_status)
    STATUS_TRANSITIONS[status]&.include?(new_status.to_s)
  end

  def has_been_accepted?
    !status.to_s.in?([PENDING, REJECTED])
  end

  def deferred_at
    return nil unless deferred_status?

    deferred_event&.created_at
  end

  def withdrawn_at
    return nil unless withdrawn_status?

    withdrawn_event&.created_at
  end

  def reason_for_rejection
    return nil unless rejected_status?

    rejected_event&.reason
  end

  def previously_funded?
    # This is an optimization used by the API Applications::Query in order
    # to speed up the bulk-retrieval of Applications.
    return transient_previously_funded if respond_to?(:transient_previously_funded)

    @previously_funded ||= user.applications
      .where.not(id:)
      .has_been_accepted
      .eligible_for_funding
      .where(funded_place: [nil, true])
      .exists?
  end

  def ineligible_for_funding_reason
    return "previously-funded" if previously_funded?

    "establishment-ineligible" unless eligible_for_funding
  end

  def inside_uk_catchment?
    teacher_catchment.in?(UK_CATCHMENT_AREA)
  end

  def inside_catchment?
    %w[england].include?(teacher_catchment)
  end

  def fundable?
    return false if previously_funded?

    eligible_for_funding && (funded_place.nil? || funded_place)
  end

  def transition_status!(status, reason: nil, metadata: {}, **attributes)
    metadata.merge!(reason:) if reason.present?
    self.class.transaction do
      state_changes.create!(event: status, lead_provider:, metadata:)
      update!(attributes.merge(status:))
    end
  end

private

  def not_admin_user?
    admin_user.blank?
  end

  def ensure_valid_status_transition
    from, to = changes[:status]
    return if from.nil? # allow setting initial status

    if STATUS_TRANSITIONS.fetch(from, []).exclude?(to)
      errors.add(:status, :invalid_status_transition, from: from || "blank", to:)
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

  def set_training_starts_at_from_course_cohort
    self.training_starts_at = course_cohort&.training_starts_at
  end
end
