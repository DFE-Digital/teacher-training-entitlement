class Course < ApplicationRecord
  include CourseGroupable

  has_paper_trail

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  has_many :course_cohorts, dependent: :destroy
  has_many :course_cohort_providers, through: :course_cohorts
  has_many :cohorts, through: :course_cohorts
  has_many :lead_providers, through: :course_cohort_providers
  has_many :schedules, through: :course_cohorts
  has_many :applications, through: :course_cohorts

  scope :displayable, -> { where(display: true).order(:position) }

  IDENTIFIERS = %w[tte-early-years].freeze
  # IDENTIFIERS = %w[npd-excellence-in-reception-teaching].freeze

  def self.reception
    find_by(identifier: "npd-excellence-in-reception-teaching") ||
      find_by(identifier: "tte-early-years")
  end

  def rebranded_alternative_courses
    [self]
  end
end
