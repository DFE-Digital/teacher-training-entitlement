class ApplicationEvent < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider, optional: true

  STATE_CHANGE_PREFIX = "StateChange::"
  NOTIFICATION_PREFIX = "Notification::"

  validates :event, presence: true
  validate :valid_event_format

  scope :state_changes, -> { where("event LIKE ?", "#{STATE_CHANGE_PREFIX}%") }

  def status
    return unless event&.start_with?(STATE_CHANGE_PREFIX)

    # for a string "StateChange::Application::DEFERRED"
    # return the constant Application::DEFERRED
    event.delete_prefix(STATE_CHANGE_PREFIX).constantize
  end

  def reason
    metadata&.dig("reason")
  end

private

  def valid_event_format
    return if event.blank?
    return if event.start_with?(STATE_CHANGE_PREFIX) || event.start_with?(NOTIFICATION_PREFIX)

    errors.add(:event, "must start with '#{STATE_CHANGE_PREFIX}' or '#{NOTIFICATION_PREFIX}'")
  end
end
