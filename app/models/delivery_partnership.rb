class DeliveryPartnership < ApplicationRecord
  belongs_to :delivery_partner
  belongs_to :lead_provider
  belongs_to :course_cohort

  validates :delivery_partner_id, presence: true
  validates :lead_provider_id, presence: true
  validates :course_cohort_id, presence: true
  validates :delivery_partner_id, uniqueness: { scope: %i[lead_provider_id course_cohort_id] }
end
