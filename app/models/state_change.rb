class StateChange < ApplicationEvent
  DEFERRAL_EXPIRY_MONTHS = 14
  DEFERRAL_WARNING_MONTHS = 11

  validates :event, inclusion: { in: Application::STATUSES }

  scope :expired_deferrals, ->(months_ago: DEFERRAL_EXPIRY_MONTHS) { deferrals("<", months_ago) }
  scope :expiring_deferrals, -> { deferrals("<=", DEFERRAL_WARNING_MONTHS) }

  # Most recent deferral date per application
  # Handles edge case: deferred 16mo ago -> resumed -> deferred 2mo ago
  scope :most_recent_deferrals, lambda {
    where(event: Application::DEFERRED)
      .group(:application_id)
      .select(:application_id, "MAX(created_at) as last_deferral_at")
  }

  def self.deferrals(comparison, months_ago)
    most_recent_deferrals
      .having("MAX(created_at) #{comparison} ?", months_ago.months.ago)
      .reselect(:application_id)
  end

  def status
    event
  end
end
