class DeliveryPartnership < ApplicationRecord
  belongs_to :delivery_partner
  belongs_to :lead_provider
  belongs_to :course

  has_many :course_cohorts, through: :course

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  validates :delivery_partner_id, presence: true
  validates :lead_provider_id, presence: true
  validates :course_id, presence: true
  validates :delivery_partner_id, uniqueness: { scope: %i[lead_provider_id course_id] }

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def archived?
    archived_at.present?
  end
end
