class DeliveryPartnership < ApplicationRecord
  belongs_to :delivery_partner
  belongs_to :lead_provider
  belongs_to :cohort, optional: true
  belongs_to :course_cohort, optional: true

  validates :delivery_partner_id, presence: true
  validates :lead_provider_id, presence: true
  validates :cohort_id, presence: true, unless: :course_cohort_id?
  validates :course_cohort_id, presence: true, unless: :cohort_id?
  validates :delivery_partner_id,
            uniqueness: { scope: %i[lead_provider_id course_cohort_id] },
            if: :course_cohort_id?
  validates :delivery_partner_id,
            uniqueness: { scope: %i[lead_provider_id cohort_id] },
            unless: :course_cohort_id?
end
