class LeadProvider < ApplicationRecord
  has_many :statements
  has_many :course_cohort_providers
  has_many :course_cohorts, through: :course_cohort_providers
  has_many :courses, through: :course_cohorts
  has_many :delivery_partnerships
  has_many :delivery_partners, -> { distinct }, through: :delivery_partnerships
  has_many :application_lead_providers
  has_many :updateable_applications,
           -> { merge(ApplicationLeadProvider.current) },
           through: :application_lead_providers, source: :application
  has_many :applications, -> { distinct },
           through: :application_lead_providers, source: :application
  has_many :contract_years

  validates :name, presence: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :alphabetical, -> { order(name: :asc) }

  def delivery_partners_for_course_cohort(course_cohort:)
    return DeliveryPartner.none unless course_cohort_providers.where(course_cohort:).exists?

    delivery_partners.where(delivery_partnerships: { course: course_cohort.course })
  end

  def cohort_start_years_by_delivery_partner
    delivery_partnerships
      .joins(course_cohorts: :course_cohort_providers)
      .where(course_cohort_providers: { lead_provider: self })
      .distinct
      .pluck("delivery_partnerships.delivery_partner_id", "course_cohorts.academic_year")
      .each_with_object(Hash.new { |hash, key| hash[key] = [] }) { |(delivery_partner_id, academic_year), years|
        years[delivery_partner_id] << academic_year if academic_year
      }
      .transform_values(&:sort)
  end
end
