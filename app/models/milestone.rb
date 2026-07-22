class Milestone < ApplicationRecord
  DECLARATION_TYPES = [
    STARTED = "started".freeze,
    RETAINED_1 = "retained-1".freeze,
    RETAINED_2 = "retained-2".freeze,
    COMPLETED = "completed".freeze,
  ].freeze

  has_paper_trail

  has_many :declarations, dependent: :restrict_with_exception
  has_many :milestone_statements
  has_many :statements, through: :milestone_statements
  belongs_to :course_cohort
  has_one :cohort, through: :course_cohort

  validates :acceptance_window_start_date, presence: true
  validates :declaration_type, inclusion: DECLARATION_TYPES
  validates :declaration_type, uniqueness: { scope: :course_cohort_id }, if: :valid_declaration_type?
  validates :statement_date, presence: true

  validate :milestone_sum_within_participant_funding

  scope :in_declaration_type_order, -> { order(:declaration_type) }
  default_scope { order(:acceptance_window_start_date) }

  enum :declaration_type,
       DECLARATION_TYPES.index_with(&:itself),
       suffix: true, validate: true

  def editable?
    acceptance_window_end_date.nil? || acceptance_window_end_date >= Time.zone.today
  end

  def attach_statements!
    statements_for_statement_date.find_each do |statement|
      milestone_statements.find_or_create_by!(statement:)
    end
  end

  def statements_for_statement_date
    return Statement.none if statement_date.blank?

    Statement
      .with_output_fee
      .where(cohort: course_cohort.cohort, month: statement_date.month, year: statement_date.year)
  end

private

  def valid_declaration_type?
    declaration_type.in?(DECLARATION_TYPES.map(&:to_s))
  end

  def milestone_sum_within_participant_funding
    return unless course_cohort&.participant_funding

    other_milestones_sum = course_cohort.milestones.where.not(id:).sum(:payment_amount)
    total_sum = other_milestones_sum + (payment_amount || 0)

    return unless total_sum > course_cohort.participant_funding

    errors.add(:payment_amount, :exceeds_participant_funding)
  end
end
