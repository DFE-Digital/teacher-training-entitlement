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

  def short_code
    super.tap do |sc|
      if sc.nil?
        message = "A course short-code types mapping is missing: #{identifier}"
        Rails.logger.warn(message)
        Sentry.capture_message(message)
      end
    end
  end

  def rebranded_alternative_courses
    [self]
  end
end
