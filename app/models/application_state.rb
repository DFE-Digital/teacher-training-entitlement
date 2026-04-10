# frozen_string_literal: true

class ApplicationState < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider, optional: true

  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  enum :status,
       Application::STATUSES.index_with(&:itself),
       suffix: true

  scope :most_recent, -> { order("created_at desc").limit(1) }
  scope :for_lead_provider, ->(lead_provider) { where(lead_provider:) }
end
