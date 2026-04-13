# frozen_string_literal: true

class ParticipantNotWithdrawnValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.any?

    validate_withdrawals(record)
  end

private

  def validate_withdrawals(record)
    return unless record.application.present? && (latest_event = latest_participant_application_event(record))
    return unless latest_event.status == Application::WITHDRAWN && latest_event.created_at <= record.declaration_date

    record
      .errors
      .add(:participant_id, :declaration_must_be_before_withdrawal_date, withdrawal_date: latest_event.created_at.rfc3339)
  end

  def latest_participant_application_event(record)
    record.application
      .application_events
      .state_changes
      .where(lead_provider: record.lead_provider)
      .order(created_at: :desc)
      .first
  end
end
