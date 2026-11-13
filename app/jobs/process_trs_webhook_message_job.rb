class ProcessTrsWebhookMessageJob < ApplicationJob
  def perform(webhook_message)
    return unless webhook_message.pending_status?

    case webhook_message.message_type
    when "trn_request.completed"
      Trs::TrnRequestCompletedProcessor.new(webhook_message).call
    when "ping"
      webhook_message.mark_processed!("pingId: #{webhook_message.message['pingId']}")
    else
      webhook_message.mark_ignored!("No processor for message type #{webhook_message.message_type}")
    end
  end
end
