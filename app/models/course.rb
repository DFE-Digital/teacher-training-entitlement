class Course < ApplicationRecord
  belongs_to :course_group, optional: true

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  IDENTIFIERS = %w[tte-early-years].freeze

  def schedule_for(cohort: Cohort.current, schedule_date: Date.current)
    course_group.schedule_for(cohort:, schedule_date:)
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

  def rebranded_alternative_courses
    [self]
  end
end
