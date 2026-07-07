class ApplicationLeadProvider < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider

  validates :lead_provider_id,
            uniqueness: {
              scope: :application_id,
              conditions: -> { where(current: true) },
            },
            if: :current?

  scope :current, -> { where(current: true) }
  scope :previous, -> { where(current: false) }

  delegate :user, :ecf_id, to: :application
end
