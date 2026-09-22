class Course < ApplicationRecord
  include CourseGroupable

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  has_many :course_cohorts, dependent: :destroy
  has_many :course_cohort_providers, through: :course_cohorts
  has_many :cohorts, through: :course_cohorts
  has_many :lead_providers, through: :course_cohort_providers
  has_many :applications, through: :course_cohorts
  has_many :milestones, dependent: :destroy

  scope :displayable, -> { where(display: true).order(:position) }

  IDENTIFIERS = [
    TTE_EARLY_YEARS = "tte-early-years".freeze,
  ].freeze
  # IDENTIFIERS = %w[npd-excellence-in-reception-teaching].freeze

  TTE_RECEPTION = "tte-reception".freeze # used to keep backward compatibility with API v1 on schedule endpoint

  def self.reception
    find_by(identifier: "npd-excellence-in-reception-teaching") ||
      find_by(identifier: "tte-early-years")
  end

  def rebranded_alternative_courses
    [self]
  end

  def identifier_for_schedule
    return TTE_RECEPTION if identifier == TTE_EARLY_YEARS

    identifier
  end
end
