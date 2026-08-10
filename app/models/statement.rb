class Statement < ApplicationRecord
  FREQUENCIES = {
    "monthly" => 1.month,
  }.with_indifferent_access.freeze

  has_paper_trail meta: { note: :version_note }
  attr_accessor :version_note

  belongs_to :lead_provider
  has_many :declarations
  has_many :clawback_declarations, -> { where(type: "ClawbackDeclaration") },
           class_name: "ClawbackDeclaration"
  has_many :milestones, through: :declarations
  has_many :contracts
  has_many :adjustments

  validates :start_date, presence: true
  # rubocop:disable Rails/UniqueValidationWithoutIndex -- index added in follow-up migration after data backfill
  validates :lead_provider_id, uniqueness: { scope: %i[start_date frequency], message: "Statement for this lead provider start_date frequency already exists" }
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  validates :ecf_id, uniqueness: { case_sensitive: false }

  validates :output_fee, inclusion: { in: [true, false] }
  validate :payment_date_on_or_after_deadline_date
  validate :changing_attributes_when_payable, on: :update
  validate :changing_attributes_when_paid, on: :update
  validates :academic_year, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :with_output_fee, ->(output_fee: true) { where(output_fee:) }
  scope :with_state, ->(*state) { where(state:) }
  scope :unpaid, -> { with_state(%w[open payable]) }
  scope :paid, -> { with_state("paid") }

  scope :current, lambda { |frequency: :monthly|
    where(state: :open, frequency:, start_date: Date.current.beginning_of_month)
  }
  scope :clawback, lambda { |frequency: :monthly|
    where(
      state: :open,
      frequency:,
      start_date: Date.current.beginning_of_month.next_month,
    )
  }

  enum :frequency, FREQUENCIES.keys.index_with(&:itself), suffix: true

  before_save :set_deadline_and_payment_date, if: -> { start_date_changed? }
  before_save :set_academic_year, if: -> { start_date_changed? }

  def self.create_current!(lead_provider:, frequency: :monthly)
    create!(
      state: :open,
      frequency:,
      start_date: Date.current.beginning_of_month,
      lead_provider:,
      ecf_id: SecureRandom.uuid,
    )
  end

  def self.create_clawback!(lead_provider:, frequency: :monthly)
    create!(
      state: :open,
      frequency:,
      start_date: Date.current.beginning_of_month.next_month,
      lead_provider:,
      ecf_id: SecureRandom.uuid,
    )
  end

  state_machine :state, initial: :open do
    state :open
    state :payable
    state :paid

    event :mark_payable do
      transition [:open] => :payable
    end

    event :mark_paid do
      transition [:payable] => :paid
    end
  end

  def mark_as_frozen!
    transaction do
      declarations.payable_state.each(&:mark_paid!)
      clawback_declarations.awaiting_clawback_state.each(&:mark_clawed_back!)
      update!(state: :paid, marked_as_paid_at: Time.zone.now)
    end
  end

  def prepare_to_freeze!
    transaction do
      declarations.eligible_state.each(&:mark_payable!)
      clawback_declarations.awaiting_clawback_state.each(&:mark_awaiting_clawback!)
      mark_payable!
    end
  end

  def marked_as_paid_with_date?
    marked_as_paid_at.present? && paid?
  end

  def allow_marking_as_paid?
    output_fee &&
      payable? &&
      (current? || future?) &&
      !marked_as_paid_at? &&
      declarations.any?
  end

  def authorising_for_payment?
    payable? && marked_as_paid_at?
  end

  def future?
    deadline_date > Date.current
  end

  def current?
    start_date <= Date.current && Date.current <= deadline_date
  end

private

  def set_academic_year
    self.academic_year = start_date.year - (start_date.month < 9 ? 1 : 0)
  end

  def set_deadline_and_payment_date
    self.deadline_date = start_date + FREQUENCIES.fetch(frequency) - 1.day
    # payment are supposed to be made within a month
    self.payment_date = start_date + FREQUENCIES.fetch(frequency) + 1.month - 1.day
  end

  def payment_date_on_or_after_deadline_date
    return unless deadline_date && payment_date
    return unless payment_date < deadline_date

    errors.add :payment_date, :invalid
  end

  def changing_attributes_when_payable
    return if errors.any?

    allowed_to_change = %w[marked_as_paid_at output_fee state]
    errors.add :base, :statement_payable if state_was == "payable" && (changed - allowed_to_change).any?
  end

  def changing_attributes_when_paid
    return if errors.any?

    errors.add :base, :statement_paid if state_was == "paid" && changed.any?
  end
end
