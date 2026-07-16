class Milestone < ApplicationRecord
  has_paper_trail

  has_many :milestone_statements
  has_many :statements, through: :milestone_statements
  belongs_to :course_cohort

  validates :acceptance_window_start_date, presence: true
  validates :declaration_type, inclusion: Declaration::DECLARATION_TYPES
  validates :declaration_type, uniqueness: { scope: :course_cohort_id }, if: :valid_declaration_type?
  validate :acceptance_window_does_not_overlap

  scope :in_declaration_type_order, -> { order(:declaration_type) }
  default_scope { order(:acceptance_window_start_date) }

  def statement_date
    statement = statements.first
    Date.new(statement.year, statement.month, 1) if statement
  end

private

  def acceptance_window_does_not_overlap
    return if course_cohort_id.blank? || acceptance_window_start_date.blank? || acceptance_window_end_date.blank?

    overlapping_milestone = Milestone
      .where(course_cohort_id:)
      .where.not(id:)
      .where(acceptance_window_start_date: ..acceptance_window_end_date)
      .where(acceptance_window_end_date: acceptance_window_start_date..)
      .exists?

    errors.add(:base, :overlapping_acceptance_window) if overlapping_milestone
  end

  def valid_declaration_type?
    declaration_type.in?(Declaration::DECLARATION_TYPES.map(&:to_s))
  end
end
