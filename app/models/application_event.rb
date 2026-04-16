class ApplicationEvent < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider, optional: true

  validates :event, presence: true

  def reason
    metadata&.dig("reason")
  end
end
