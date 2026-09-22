class Milestone < ApplicationRecord
  self.ignored_columns += %w[acceptance_window_start_date acceptance_window_end_date]

  DECLARATION_TYPES = [
    STARTED = "started".freeze,
    RETAINED_1 = "retained-1".freeze,
    RETAINED_2 = "retained-2".freeze,
    COMPLETED = "completed".freeze,
  ].freeze

  has_paper_trail

  has_many :declarations, dependent: :restrict_with_exception
  belongs_to :course, optional: true
  has_many :course_cohorts, through: :course
  has_many :cohorts, through: :course_cohorts

  validates :acceptance_window_start_offset, presence: true
  validates :acceptance_window_start_offset, numericality: { only_integer: true }, allow_nil: true
  validates :acceptance_window_end_offset, numericality: { only_integer: true }, allow_nil: true
  validates :declaration_type, inclusion: DECLARATION_TYPES
  validates :declaration_type, uniqueness: { scope: :course_id }, if: :valid_declaration_type?

  scope :in_declaration_type_order, lambda {
    order(
      Arel.sql(
        DECLARATION_TYPES.each_with_index.map { |declaration_type, index| "WHEN '#{declaration_type}' THEN #{index}" }
                         .join(" ")
                         .then { |order_clause| "CASE declaration_type #{order_clause} END" },
      ),
    )
  }
  scope :started, -> { where(declaration_type: STARTED) }
  scope :completed, -> { where(declaration_type: COMPLETED) }

  default_scope { order(:acceptance_window_start_offset) }

  enum :declaration_type,
       DECLARATION_TYPES.index_with(&:itself),
       suffix: true, validate: true

  def acceptance_window_start_date_for(training_starts_at:)
    return if training_starts_at.nil? || acceptance_window_start_offset.nil?

    training_starts_at.advance(months: acceptance_window_start_offset)
  end

  def acceptance_window_end_date_for(training_starts_at:)
    return if training_starts_at.nil? || acceptance_window_end_offset.nil?

    training_starts_at.advance(months: acceptance_window_end_offset)
  end

private

  def valid_declaration_type?
    declaration_type.in?(DECLARATION_TYPES.map(&:to_s))
  end
end
