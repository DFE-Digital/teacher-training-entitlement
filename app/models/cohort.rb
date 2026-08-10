class Cohort < ApplicationRecord
  before_validation :set_start_year
  before_validation :set_identifier

  has_many :course_cohorts, dependent: :destroy
  has_many :courses, through: :course_cohorts
  has_many :schedules, through: :course_cohorts

  validates :start_year,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 2021,
              less_than: 2030,
            }

  validates :description,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { within: 5..50 }

  validates :registration_starts_at, presence: true
  validates :identifier, presence: true
  validate :identifier_is_unique
  validates :funding_cap, inclusion: { in: [true, false] }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  validate :changing_funding_cap_with_dependent_applications

  scope :order_by_latest, -> { order(registration_starts_at: :desc) }
  scope :order_by_oldest, -> { order(registration_starts_at: :asc) }

  scope :prior_to, lambda { |cohort|
    where(registration_starts_at: ...cohort.registration_starts_at)
  }

  def self.current(timestamp = Time.zone.today)
    order(registration_starts_at: :desc).where(registration_starts_at: ..timestamp).first!
  end

  def registration_open?
    Time.zone.today >= registration_starts_at &&
      (registration_ends_at.nil? || Time.zone.today <= registration_ends_at)
  end

  def registration_upcoming?
    registration_starts_at > Time.zone.today
  end

  def name
    description
  end

private

  def set_start_year
    return if registration_starts_at.blank?

    self.start_year = registration_starts_at.year
  end

  def set_identifier
    return if registration_starts_at.blank?

    self.identifier = registration_starts_at.strftime("%Y-%B")
  end

  def identifier_is_unique
    return if identifier.blank?

    duplicate = Cohort.where.not(id:).where("LOWER(identifier) = ?", identifier.downcase).exists?
    return unless duplicate

    errors.add(:identifier, :taken, cohort_start: registration_starts_at.strftime("%b %Y"))
  end

  def changing_funding_cap_with_dependent_applications
    return unless funding_cap_changed? && Application.joins(:course_cohort).where(course_cohorts: { cohort: self }).any?

    errors.add(:funding_cap, "Cannot change funding_cap when there are existing applications for this cohort")
  end
end
