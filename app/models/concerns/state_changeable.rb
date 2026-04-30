# Logs a state changes event when the status changes
#
# Including class needs:
#   - status attribute
#   - state_changes association
#   - lead_provider association (optional)
#
module StateChangeable
  extend ActiveSupport::Concern

  included do
    attr_accessor :state_change_reason

    after_save :record_state_change, if: :status_changed_from_previous?
  end

  def status_changed_from_previous?
    # only record if a state has changed - skips Pending
    saved_change_to_status&.first.present?
  end

private

  def record_state_change
    metadata = { reason: state_change_reason }.compact
    state_changes.create!(event: status, lead_provider:, metadata:)
  end
end
