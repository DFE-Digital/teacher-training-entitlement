class CourseCohort < ApplicationRecord
  TERM_IDENTIFIERS = {
    autumn: [9, 10, 11, 12],
    spring: [1, 2, 3, 4],
    summer: [5, 6, 7, 8],
  }.freeze

  belongs_to :course
  belongs_to :cohort

  has_many :course_cohort_providers, dependent: :destroy
  has_many :lead_providers, through: :course_cohort_providers
  has_many :delivery_partnerships, dependent: :destroy
  has_many :delivery_partners, through: :delivery_partnerships

  has_many :applications
  has_many :milestones, through: :course

  has_one :started_milestone,
          -> { started },
          through: :course,
          source: :milestones
  has_one :completed_milestone,
          -> { completed },
          through: :course,
          source: :milestones
  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :course_id, uniqueness: { scope: :cohort_id }
  validates :academic_year, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :registrable, lambda {
    includes(:cohort)
      .where(cohort: { registration_starts_at: ..Date.current, registration_ends_at: Date.current.. })
      .or(where(cohort: { registration_starts_at: ..Date.current, registration_ends_at: nil }))
  }

  delegate :registration_starts_at, :registration_ends_at, to: :cohort, prefix: true

  def self.next_open_for(course:)
    course_cohorts = course.course_cohorts.includes(:cohort).select do |course_cohort|
      course_cohort.cohort.start_year >= Time.zone.now.year
    end

    course_cohorts.select { |course_cohort| course_cohort.cohort.registration_open? }
                  .min_by { |course_cohort| course_cohort.cohort.registration_starts_at } ||
      course_cohorts.select { |course_cohort| course_cohort.cohort.registration_upcoming? }
                    .min_by { |course_cohort| course_cohort.cohort.registration_starts_at }
  end

  def self.school_term(date)
    return unless date

    month = date.month
    TERM_IDENTIFIERS.find { |_term, months| months.include?(month) }&.first
  end

  def name
    cohort.name
  end

  def schedule_identifier
    [course.identifier_for_schedule, term_identifier].join("-")
  end

  def training_live?
    training_started? && !training_ended?
  end

  def training_started?
    return false if started_milestone.nil? || training_starts_at.nil?

    started_milestone.acceptance_window_start_date_for(training_starts_at:) <= Time.zone.today
  end

  def training_ended?
    return false if completed_milestone.nil? || training_starts_at.nil?

    completed_milestone.acceptance_window_end_date_for(training_starts_at:) <= Time.zone.today
  end

  def taken_declaration_types(except: nil)
    milestones.where.not(id: except&.id).pluck(:declaration_type)
  end
end
