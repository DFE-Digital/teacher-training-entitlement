class CourseCohort < ApplicationRecord
  belongs_to :course
  belongs_to :cohort
  belongs_to :schedule, optional: true, deprecated: true

  has_many :course_cohort_providers, dependent: :destroy
  has_many :lead_providers, through: :course_cohort_providers
  has_many :delivery_partnerships, dependent: :destroy
  has_many :delivery_partners, through: :delivery_partnerships

  has_many :applications
  has_many :milestones, dependent: :destroy

  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :course_id, uniqueness: { scope: :cohort_id }
  validates :academic_year, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  delegate :name, to: :cohort

  def self.next_open_for(course:)
    course_cohorts = course.course_cohorts.includes(:cohort).select do |course_cohort|
      course_cohort.cohort.start_year >= Time.zone.now.year
    end

    course_cohorts.select { |course_cohort| course_cohort.cohort.registration_open? }
                  .min_by { |course_cohort| course_cohort.cohort.registration_starts_at } ||
      course_cohorts.select { |course_cohort| course_cohort.cohort.registration_upcoming? }
                    .min_by { |course_cohort| course_cohort.cohort.registration_starts_at }
  end

  def application_started_confirmed_by_date
    date = schedule.training_ends_at
    "#{date.month.between?(1, 4) ? 'Spring' : 'Summer'} #{date.year}"
  end

  def taken_declaration_types(except: nil)
    milestones.where.not(id: except&.id).pluck(:declaration_type)
  end
end
