class ApplicationEvent < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider, optional: true

  STATE_CHANGE_EVENTS = {
    Application::PENDING => "StateChange::Application::PENDING",
    Application::ACCEPTED => "StateChange::Application::ACCEPTED",
    Application::STARTED => "StateChange::Application::STARTED",
    Application::COMPLETED => "StateChange::Application::COMPLETED",
    Application::DEFERRED => "StateChange::Application::DEFERRED",
    Application::WITHDRAWN => "StateChange::Application::WITHDRAWN",
    Application::REJECTED => "StateChange::Application::REJECTED",
  }.freeze

  NOTIFICATION_PREFIX = "Notification::".freeze

  validates :event, presence: true
  validate :valid_event_format

  scope :state_changes, -> { where(event: STATE_CHANGE_EVENTS.values) }

  def status
    STATE_CHANGE_EVENTS.key(event)
  end

  def reason
    metadata&.dig("reason")
  end

private

  def valid_event_format
    return if event.blank?
    return if STATE_CHANGE_EVENTS.value?(event) || event.start_with?(NOTIFICATION_PREFIX)

    errors.add(:event, :invalid)
  end
end
