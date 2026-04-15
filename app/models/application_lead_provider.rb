class ApplicationLeadProvider < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider
end
