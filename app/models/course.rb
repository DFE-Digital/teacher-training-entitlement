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

  def self.reception
    find_by(identifier: "tte-early-years")
  end

  def course_short_code
    I18n.t(identifier, scope: "course.short_code")
  end

  def localise_course_name
    I18n.t(identifier, scope: "course.name")
  end

  # Returns either "the #{course_name} TTE"
  def localise_sentence_embedded_course_name
    I18n.t("course.embedded_sentence.default", course_name: localise_course_name)
  end

  def rebranded_alternative_courses
    [self]
  end

  def short_code
    super.tap do |sc|
      if sc.nil?
        message = "A course short-code types mapping is missing: #{identifier}"
        Rails.logger.warn(message)
        Sentry.capture_message(message)
      end
    end
  end

  def title_embedded_course_name
    I18n.t("course.embedded_sentence.title", course_name: localise_course_name)
  end
end
