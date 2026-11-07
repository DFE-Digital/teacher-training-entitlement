class DeliveryPartnership < ApplicationRecord
  belongs_to :delivery_partner
  belongs_to :lead_provider
  belongs_to :course

  has_many :course_cohorts, through: :course

  validates :delivery_partner_id, presence: true
  validates :lead_provider_id, presence: true
  validates :course_id, presence: true
  validates :delivery_partner_id, uniqueness: { scope: %i[lead_provider_id course_id] }
end
