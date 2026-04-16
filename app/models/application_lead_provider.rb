class ApplicationLeadProvider < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider

  scope :current, -> { where(current: true) }
  scope :previous, -> { where(current: false) }
end
