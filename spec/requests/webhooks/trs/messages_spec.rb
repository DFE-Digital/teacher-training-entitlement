require "rails_helper"

RSpec.describe "POST /webhooks/trs/messages", type: :request do
  subject(:deliver) { post(webhooks_trs_messages_path, params: body, headers:) }

  let(:message_id) { SecureRandom.uuid }
  let(:sent_at) { Time.current.change(usec: 0) }
  let(:body) { { trnRequest: { oneLoginUserSubject: "one-login-id", trn: "1234567" } }.to_json }
  let(:headers) do
    signed_trs_webhook_headers(
      body:,
      signed_at: sent_at,
      headers: {
        "content-type" => "application/json",
        "ce-id" => message_id,
        "ce-source" => "https://preprod.teacher-qualifications-api.education.gov.uk/",
      },
    )
  end

  before { trust_trs_webhook_signing_key }

  it "stores the message and queues it for processing" do
    expect { deliver }.to have_enqueued_job(ProcessTrsWebhookMessageJob)

    expect(response).to have_http_status(:ok)
    expect(TrsWebhookMessage.sole).to have_attributes(
      message_id:,
      message_type: "trn_request.completed",
      status: "pending",
      sent_at:,
      message: JSON.parse(body),
    )
  end

  context "when TRS redelivers a message it has already sent" do
    before { create(:trs_webhook_message, message_id:) }

    it "acknowledges it without storing or processing it again" do
      expect { deliver }.not_to have_enqueued_job(ProcessTrsWebhookMessageJob)

      expect(response).to have_http_status(:ok)
      expect(TrsWebhookMessage.count).to eq(1)
    end
  end

  context "when the body is not JSON" do
    let(:body) { "not json" }

    it "responds bad request and stores nothing" do
      deliver

      expect(response).to have_http_status(:bad_request)
      expect(TrsWebhookMessage.count).to eq(0)
    end
  end

  context "when the signature is invalid" do
    before { headers["ce-type"] = "ping" }

    it "responds unauthorized and stores nothing" do
      expect { deliver }.not_to have_enqueued_job(ProcessTrsWebhookMessageJob)

      expect(response).to have_http_status(:unauthorized)
      expect(TrsWebhookMessage.count).to eq(0)
    end

    it "reports to Sentry" do
      allow(Sentry).to receive(:capture_message)

      deliver

      expect(Sentry).to have_received(:capture_message).with(/\A\[TRS webhook\] Rejected message: /, hash_including(level: :warning, extra: { message_id: }))
    end
  end
end
