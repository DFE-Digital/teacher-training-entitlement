class Course < ApplicationRecord
  include CourseGroupable

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  has_many :course_cohorts, dependent: :destroy
  has_many :course_cohort_providers, through: :course_cohorts
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

  def next_open_cohort
    @next_open_cohort ||= begin
      cohorts = course_cohorts.includes(:cohort).map(&:cohort).select { |c| c.start_year >= Time.zone.now.year }
      cohorts.select(&:registration_open?).min_by(&:registration_starts_at) ||
        cohorts.select(&:registration_upcoming?).min_by(&:registration_starts_at)
    end
  end

  def next_cohort_start_date
    return "Registration closed" if next_open_cohort.nil?

    next_open_cohort.name
  end

  def application_started_confirmed_by_date
    return "Registration closed" if next_open_cohort.nil?

    if next_open_cohort.registration_ends_at.between?(9, 11)
      "Spring #{next_open_cohort.registration_ends_at.year + 1}"
    else
      "Summer #{next_open_cohort.registration_ends_at.year}"
    end
  end

  def rebranded_alternative_courses
    [self]
  end
end
