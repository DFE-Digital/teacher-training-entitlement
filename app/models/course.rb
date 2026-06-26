class Course < ApplicationRecord
  include CourseGroupable

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  has_many :cohorts
  has_many :cohort_providers, through: :cohorts
  has_many :lead_providers, through: :cohort_providers
  # has_many :schedules, through: :course_cohorts
  has_many :applications

  scope :displayable, -> { where(display: true).order(:position) }

  IDENTIFIERS = %w[tte-early-years].freeze
  # IDENTIFIERS = %w[npd-excellence-in-reception-teaching].freeze

  def self.reception
    find_by(identifier: "npd-excellence-in-reception-teaching") ||
      find_by(identifier: "tte-early-years")
  end

  def next_open_cohort
    course_cohorts = cohorts.select do |cohort|
      cohort.start_year >= Time.zone.now.year
    end

    course_cohorts.select(&:registration_open?)
                  .min_by(&:registration_starts_at) ||
      course_cohorts.select(&:registration_upcoming?)
                    .min_by(&:registration_starts_at)
  end

  def rebranded_alternative_courses
    [self]
  end
end
