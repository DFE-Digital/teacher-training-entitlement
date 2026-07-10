class Cohort < ApplicationRecord
  before_validation :set_start_year
  before_validation :set_identifier

  belongs_to :course, optional: true

  has_many :declarations, dependent: :restrict_with_exception
  has_many :applications
  has_many :statements, dependent: :restrict_with_exception
  has_many :delivery_partnerships, dependent: :destroy
  has_many :delivery_partners, through: :delivery_partnerships
  has_many :cohort_providers, dependent: :destroy
  has_many :lead_providers, through: :cohort_providers
  has_many :schedules, dependent: :destroy

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
  validates :training_starts_at, presence: true, if: -> { new_record? || training_starts_at_was }
  validates :training_ends_at, presence: true, if: -> { new_record? || training_ends_at_was }
  validates :identifier, presence: true
  validate :identifier_is_unique
  validates :funding_cap, inclusion: { in: [true, false] }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  validate :changing_funding_cap_with_dependent_applications

  scope :order_by_latest, -> { order(registration_starts_at: :desc) }
  scope :order_by_oldest, -> { order(registration_starts_at: :asc) }
  scope :training_live, -> { where(training_starts_at: ..Time.zone.today, training_ends_at: Time.zone.today..) }

  scope :prior_to, lambda { |cohort|
    where(registration_starts_at: ...cohort.registration_starts_at)
  }

  def self.current(timestamp = Time.zone.today)
    order(registration_starts_at: :desc).where(registration_starts_at: ..timestamp).first!
  end

  def application_started_confirmed_by_date
    "#{training_ends_at.month.between?(1, 4) ? 'Spring' : 'Summer'} #{training_ends_at.year}"
  end

  def registration_open?
    Time.zone.today >= registration_starts_at &&
      (registration_ends_at.nil? || Time.zone.today <= registration_ends_at)
  end

  def registration_upcoming?
    registration_starts_at > Time.zone.today
  end

  def training_live?
    training_starts_at <= Time.zone.today && training_ends_at >= Time.zone.today
  end

  def allowed_declaration_types
    Schedule.allowed_declaration_types
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
    return unless self.class.where.not(id:).where("LOWER(identifier) = ?", identifier.downcase).exists?

    errors.add(:identifier, :taken, cohort_start: registration_starts_at&.strftime("%b %Y") || identifier)
  end

  def changing_funding_cap_with_dependent_applications
    return unless funding_cap_changed? && Application.where(cohort: self).any?

    errors.add(:funding_cap, "Cannot change funding_cap when there are existing applications for this cohort")
  end
end
