class Milestone < ApplicationRecord
  has_paper_trail

  has_many :milestone_statements
  has_many :statements, through: :milestone_statements
  belongs_to :course_cohort

  validates :acceptance_window_start_date, presence: true
  validates :declaration_type, inclusion: Declaration::DECLARATION_TYPES
  validates :declaration_type, uniqueness: { scope: :course_cohort_id }, if: :valid_declaration_type?

  validate :milestone_sum_within_participant_funding

  scope :in_declaration_type_order, -> { order(:declaration_type) }
  default_scope { order(:acceptance_window_start_date) }

  def statement_date
    statement = statements.first
    Date.new(statement.year, statement.month, 1) if statement
  end

private

  def valid_declaration_type?
    declaration_type.in?(Declaration::DECLARATION_TYPES.map(&:to_s))
  end

  def milestone_sum_within_participant_funding
    return unless course_cohort&.participant_funding

    other_milestones_sum = course_cohort.milestones.where.not(id:).sum(:payment_amount)
    total_sum = other_milestones_sum + (payment_amount || 0)

    return unless total_sum > course_cohort.participant_funding

    errors.add(:payment_amount, :exceeds_participant_funding)
  end
end
