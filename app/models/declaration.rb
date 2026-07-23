class Declaration < ApplicationRecord
  REVERTABLE_STATES = %w[ineligible voided].freeze
  BILLABLE_STATES = %w[eligible payable paid].freeze
  UNIQUE_MILESTONE_STATES = (BILLABLE_STATES + %w[submitted]).freeze
  CHANGEABLE_STATES = %w[eligible submitted].freeze
  UPLIFT_PAID_STATES = %w[paid].freeze
  VOIDABLE_STATES = %w[submitted eligible payable ineligible].freeze
  DELIVER_PARTNER_REQUIRED_FROM = 2024

  has_paper_trail ignore: [:updated_at]

  belongs_to :statement
  belongs_to :application
  belongs_to :lead_provider
  belongs_to :cohort, deprecated: true, optional: true
  belongs_to :milestone, optional: true
  belongs_to :superseded_by, class_name: "Declaration", optional: true
  belongs_to :delivery_partner, optional: true
  belongs_to :secondary_delivery_partner, class_name: "DeliveryPartner", optional: true
  belongs_to :clawback_declaration, optional: true
  belongs_to :paid_declaration, class_name: "Declaration", optional: true
  has_one :course_cohort, through: :milestone
  has_many :participant_outcomes, dependent: :destroy

  delegate :course, :user, to: :application
  delegate :inside_catchment?, to: :application, prefix: true, allow_nil: true
  delegate :identifier, to: :course, prefix: true
  delegate :name, to: :lead_provider, prefix: true

  scope :billable, -> { where(state: BILLABLE_STATES, clawback_declaration: nil) }
  scope :changeable, -> { where(state: CHANGEABLE_STATES) }
  scope :billable_or_changeable, -> { billable.or(changeable) }
  scope :voidable, -> { where(state: VOIDABLE_STATES) }
  scope :billable_or_voidable, -> { billable.or(voidable) }
  scope :awaiting_clawback, -> { where(state: :awaiting_clawback) }
  scope :with_lead_provider, ->(lead_provider) { where(lead_provider:) }
  scope :completed, -> { where(declaration_type: Milestone::COMPLETED) }
  scope :with_course_identifier, ->(course_identifier) { joins(application: { course_cohort: :course }).where(courses: { identifier: course_identifier }) }
  scope :latest_first, -> { order(created_at: :desc, id: :desc) }
  scope :started, -> { where(declaration_type: Milestone::STARTED) }
  scope :not_voided, -> { where.not(state: :voided) }

  scope :eligible_for_outcomes, lambda { |lead_provider, course_identifier|
    completed
    .with_lead_provider(lead_provider)
    .with_course_identifier(course_identifier)
    .billable_or_voidable
    .latest_first
  }

  enum :state, {
    submitted: "submitted",
    eligible: "eligible",
    ineligible: "ineligible",
    voided: "voided",
    payable: "payable",
    paid: "paid",
  }, suffix: true

  state_machine :state, initial: :submitted do
    event :mark_eligible do
      transition %i[submitted] => :eligible
    end

    event :mark_ineligible do
      transition %i[submitted] => :ineligible
    end

    event :mark_voided do
      transition %i[submitted eligible payable ineligible] => :voided
    end

    event :revert_to_eligible do
      transition %i[payable] => :eligible
    end

    event :mark_payable do
      transition %i[eligible] => :payable
    end

    event :mark_paid do
      transition %i[payable] => :paid
    end
  end

  enum :declaration_type,
       Milestone::DECLARATION_TYPES.index_with(&:itself),
       suffix: true, validate: true

  enum :state_reason, {
    duplicate: "duplicate",
  }, suffix: true

  validates :declaration_date, :declaration_type, presence: true
  validate :validate_declaration_date_within_schedule
  validate :validate_declaration_date_not_in_the_future
  validates :ecf_id, uniqueness: { case_sensitive: false }

  validates :delivery_partner_id, presence: true, if: :delivery_partner_required
  validates :delivery_partner_id, absence: { message: :overseas },
                                  unless: :application_inside_catchment?
  validates :delivery_partner_id, inclusion: { in: :available_delivery_partner_ids },
                                  if: -> { delivery_partner && delivery_partner_changed? }

  validates :secondary_delivery_partner_id, absence: true, unless: :delivery_partner

  validates :secondary_delivery_partner_id,
            absence: { message: :overseas },
            if: -> { delivery_partner_id && !application_inside_catchment? }

  validates :secondary_delivery_partner_id,
            inclusion: { in: :available_delivery_partner_ids },
            if: -> { secondary_delivery_partner && secondary_delivery_partner_changed? }

  validate :delivery_partners_are_not_the_same, if: :delivery_partner

  validates :milestone_id,
            uniqueness: { scope: :application_id, conditions: -> { where(state: UNIQUE_MILESTONE_STATES) } },
            if: -> { milestone_id.present? && state.in?(UNIQUE_MILESTONE_STATES) }

  validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :for_delivery_partners, lambda { |delivery_partner|
    where(delivery_partner: delivery_partner)
      .or(where(secondary_delivery_partner: delivery_partner))
  }

  def clawback!
    self.clawback_declaration = ClawbackDeclaration.new(
      paid_declaration: self,
      application: application,
      milestone: milestone,
      cohort: cohort,
      # statement: Statement.open.find_or_create_by(contract: @declaration.milestone.contract),
      lead_provider: lead_provider,
      delivery_partner: delivery_partner,
      secondary_delivery_partner: secondary_delivery_partner,
      declaration_type: declaration_type,
      declaration_date: declaration_date,
      state: "awaiting_clawback",
    )
    save!
  end

  def billable_statement
    statement_items.find(&:billable?)&.statement
  end

  def refundable_statement
    statement_items.find(&:refundable?)&.statement
  end

  def uplift_paid?
    state.in?(UPLIFT_PAID_STATES) && started_declaration_type?
  end

  def eligible_for_payment?
    can_mark_paid? || can_mark_payable?
  end

  def ineligible_for_funding_reason
    return unless ineligible_state?

    case state_reason
    when "duplicate"
      "duplicate_declaration"
    else
      state_reason
    end
  end

  def duplicate_declarations
    self
      .class
      .billable_or_changeable
      .joins(application: [:user, { course_cohort: :course }])
      .where(user: { trn: application.user.trn })
      .where.not(user: { trn: nil })
      .where.not(user: { id: application.user_id })
      .where.not(id:)
      .where(
        declaration_type:,
        superseded_by_id: nil,
        courses: { id: application.course.rebranded_alternative_courses },
      )
  end

  def available_delivery_partner_ids
    return [] unless lead_provider && milestone&.cohort

    lead_provider.delivery_partners_for_cohort(milestone&.cohort).map(&:id)
  end

  def delivery_partners
    [delivery_partner, secondary_delivery_partner].compact
  end

  def state_history
    changes = versions.where_attribute_changes(:state).order(created_at: :asc, id: :asc)

    return [[state, created_at]] if changes.none?

    result = changes.map { |v| [v.object_changes.dig("state", 1), v.created_at] }
    result.prepend([changes.first.object_changes.dig("state", 0), created_at]) unless changes.first.created_at == created_at
    result
  end

private

  def validate_declaration_date_within_schedule
    return unless application&.schedule
    return unless declaration_date
    return if persisted? && !declaration_date_changed?

    if declaration_date < application.schedule.training_starts_at
      errors.add(:declaration_date, :declaration_before_schedule_start)
    end
  end

  def validate_declaration_date_not_in_the_future
    errors.add(:declaration_date, :future_declaration_date) if declaration_date&.future?
  end

  def delivery_partners_are_not_the_same
    if delivery_partner == secondary_delivery_partner
      errors.add :secondary_delivery_partner_id, :duplicate_delivery_partner
    end
  end

  def delivery_partner_required
    return false unless milestone&.cohort
    return false unless application_inside_catchment?
    return false if persisted? && !delivery_partner_id_changed?

    milestone.cohort.start_year >= DELIVER_PARTNER_REQUIRED_FROM
  end
end
