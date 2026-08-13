class Milestone < ApplicationRecord
  DECLARATION_TYPES = [
    STARTED = "started".freeze,
    RETAINED_1 = "retained-1".freeze,
    RETAINED_2 = "retained-2".freeze,
    COMPLETED = "completed".freeze,
  ].freeze

  has_paper_trail

  has_many :declarations, dependent: :restrict_with_exception
  belongs_to :course_cohort
  has_one :cohort, through: :course_cohort

  validates :acceptance_window_start_date, presence: true
  validates :declaration_type, inclusion: DECLARATION_TYPES
  validates :declaration_type, uniqueness: { scope: :course_cohort_id }, if: :valid_declaration_type?

  scope :in_declaration_type_order, -> { order(:declaration_type) }
  default_scope { order(:acceptance_window_start_date) }

  enum :declaration_type,
       DECLARATION_TYPES.index_with(&:itself),
       suffix: true, validate: true

  def editable?
    acceptance_window_end_date.nil? || acceptance_window_end_date >= Time.zone.today
  end

private

  def valid_declaration_type?
    declaration_type.in?(DECLARATION_TYPES.map(&:to_s))
  end
end
