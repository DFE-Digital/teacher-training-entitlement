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
  scope :preferred_per_application, lambda {
    select("DISTINCT ON (application_id) application_lead_providers.id")
      .order(:application_id, current: :desc, updated_at: :desc, id: :desc)
  }

  delegate :user, :ecf_id, to: :application
end
