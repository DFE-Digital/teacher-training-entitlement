class ApplicationEvent < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider, optional: true

  validates :event, presence: true

  before_create :set_lead_provider

  def reason
    metadata&.dig("reason")
  end

private

  def set_lead_provider
    return if lead_provider_id.present?

    self.lead_provider_id = application.current_application_lead_provider&.lead_provider_id
  end
end
