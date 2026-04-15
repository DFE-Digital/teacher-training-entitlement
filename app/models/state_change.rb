class StateChange < ApplicationEvent
  validates :event, inclusion: { in: Application::STATUSES }

  # Handles edge case: deferred 16mo ago -> resumed -> deferred 2mo ago
  # Uses MAX(created_at) to check most recent deferral only
  scope :expired_deferrals, lambda { |months_ago:|
    where(event: Application::DEFERRED)
      .group(:application_id)
      .having("MAX(created_at) < ?", months_ago.months.ago)
      .select(:application_id)
  }

  def status
    event
  end
end
