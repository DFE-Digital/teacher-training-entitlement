class Milestone < ApplicationRecord
  has_paper_trail

  has_many :milestone_statements
  has_many :statements, through: :milestone_statements
  belongs_to :course_cohort

  validates :acceptance_window_start_date, presence: true
  validates :declaration_type, inclusion: Declaration::DECLARATION_TYPES
  validates :declaration_type, uniqueness: { scope: :course_cohort_id }, if: :valid_declaration_type?

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
end
