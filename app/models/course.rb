class Course < ApplicationRecord
  include CourseGroupable

  IDENTIFIERS = [
    TTE_EARLY_YEARS = "tte-early-years".freeze,
    SEND_INCLUSIVE_TEACHERS = "npd-send-eip".freeze,
    SEND_INCLUSIVE_LEADERS = "npd-send-eipl".freeze,
  ].freeze

  TTE_RECEPTION = "tte-reception".freeze # used to keep backward compatibility with API v1 on schedule endpoint

  has_many :milestones, dependent: :destroy
  has_many :delivery_partnerships, dependent: :destroy
  has_many :active_delivery_partnerships, -> { active }, class_name: "DeliveryPartnership"
  has_many :delivery_partners, through: :active_delivery_partnerships
  has_many :course_cohorts, dependent: :destroy
  has_many :course_cohort_providers, through: :course_cohorts
  has_many :cohorts, through: :course_cohorts
  has_many :applications, through: :course_cohorts
  has_many :contract_years
  has_many :lead_provider_profiles, -> { where(academic_year: nil) }, class_name: "ContractYear"
  has_many :lead_providers, through: :lead_provider_profiles

  scope :displayable, -> { where(display: true).order(:position) }

  before_validation :set_defaults, on: :create

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  def self.reception
    find_by(identifier: TTE_RECEPTION) ||
      find_by(identifier: TTE_EARLY_YEARS)
  end

  def identifier_for_schedule
    return TTE_RECEPTION if identifier == TTE_EARLY_YEARS

    identifier
  end

  def application_creation_service_class_name
    if identifier.in?([TTE_RECEPTION, TTE_EARLY_YEARS])
      Registrations::ExcellenceInReception::ApplicationCreation.name
    elsif identifier.in?([SEND_INCLUSIVE_TEACHERS, SEND_INCLUSIVE_LEADERS])
      Registrations::SendInclusivePractice::ApplicationCreation.name
    end
  end

  def funding_eligibility_service_class
    if identifier.in?([TTE_RECEPTION, TTE_EARLY_YEARS])
      Registrations::ExcellenceInReception::FundingEligibility
    elsif identifier.in?([SEND_INCLUSIVE_TEACHERS, SEND_INCLUSIVE_LEADERS])
      Registrations::SendInclusivePractice::FundingEligibility
    end
  end

private

  def set_defaults
    return if name.blank?

    self.identifier = name.parameterize if identifier.blank?
    self.short_code = "NPD#{name.upcase.gsub(" ", "")[0..2]}" if short_code.blank?
    self.ecf_id = SecureRandom.uuid if ecf_id.blank?
  end
end
