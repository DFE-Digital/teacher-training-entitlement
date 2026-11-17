class TrsWebhookMessage < ApplicationRecord
  enum :status, {
    pending: "pending",
    processed: "processed",
    failed: "failed",
    ignored: "ignored",
  }, suffix: true

  validates :message_id, :message_type, :sent_at, presence: true

  def self.receive!(message_id:, **attributes)
    webhook_message = create_or_find_by!(message_id:) { |record| record.assign_attributes(attributes) }
    ProcessTrsWebhookMessageJob.perform_later(webhook_message) if webhook_message.previously_new_record?
    webhook_message
  end

  def mark_processed!(comment = nil)
    update!(status: :processed, status_comment: comment, processed_at: Time.current)
  end

  def mark_ignored!(comment)
    update!(status: :ignored, status_comment: comment, processed_at: Time.current)
    report_to_sentry(comment, level: :warning)
  end

  def mark_failed!(comment)
    update!(status: :failed, status_comment: comment, processed_at: Time.current)
    report_to_sentry(comment, level: :error)
  end

private

  def report_to_sentry(comment, level:)
    Sentry.capture_message("[TRS webhook] #{comment}", level:, extra: { trs_webhook_message_id: id, message_type: })
  end
end
