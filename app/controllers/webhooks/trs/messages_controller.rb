class Webhooks::Trs::MessagesController < WebhooksController
  skip_before_action :authenticate
  before_action :verify_signature

  rescue_from JSON::ParserError, ActiveRecord::RecordInvalid, with: :bad_request_response

  def create
    TrsWebhookMessage.receive!(
      message_id: request.headers["ce-id"],
      message_type: request.headers["ce-type"],
      message_source: request.headers["ce-source"],
      sent_at: Time.zone.parse(request.headers["ce-time"].to_s),
      message: JSON.parse(request.raw_post),
    )

    head :ok
  end

private

  def verify_signature
    Trs::WebhookSignature.new(request).call
  rescue Trs::WebhookSignature::InvalidSignature => e
    Rails.logger.warn("[TRS webhook] Rejected message #{request.headers['ce-id']}: #{e.message}")
    head :unauthorized
  end
end
