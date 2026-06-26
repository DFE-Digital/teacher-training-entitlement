class LeadProvider < ApplicationRecord
  has_many :statements
  has_many :cohort_providers
  has_many :cohorts, through: :cohort_providers
  has_many :courses, through: :cohorts
  has_many :delivery_partnerships
  has_many :delivery_partners, -> { distinct }, through: :delivery_partnerships
  has_many :application_lead_providers
  has_many :updateable_applications,
           -> { merge(ApplicationLeadProvider.current) },
           through: :application_lead_providers, source: :application
  has_many :applications, -> { distinct },
           through: :application_lead_providers, source: :application

  validates :name, presence: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :alphabetical, -> { order(name: :asc) }

  def next_output_fee_statement(cohort)
    statements.next_output_fee_statements.where(cohort:).first
  end

  def delivery_partners_for_cohort(cohort)
    delivery_partners.where(delivery_partnerships: { cohort: })
  end
end
