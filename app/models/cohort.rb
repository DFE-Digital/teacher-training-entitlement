class Cohort < ApplicationRecord
  before_validation :set_identifier

  has_many :declarations, dependent: :restrict_with_exception
  has_many :statements, dependent: :restrict_with_exception
  has_many :delivery_partnerships, dependent: :destroy
  has_many :delivery_partners, through: :delivery_partnerships
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
  validate :registration_starts_at_matches_start_year
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

  def self.course_start_date
    if Time.zone.now.month.between?(1, 3)
      "January to March #{current.start_year}"
    else
      "October #{current.start_year}"
    end
  end

  def self.next_course_start_date
    if Time.zone.now.month.between?(1, 3)
      "October #{current.start_year}"
    else
      "January to March #{current.start_year + 1}"
    end
  end

  def name
    start_year.to_s
  end

private

  def registration_starts_at_matches_start_year
    return if registration_starts_at.blank?

    errors.add(:registration_starts_at, "year must match the start year") if registration_starts_at.year != start_year
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
