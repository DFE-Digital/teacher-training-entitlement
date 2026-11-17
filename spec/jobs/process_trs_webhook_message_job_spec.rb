require "rails_helper"

RSpec.describe ProcessTrsWebhookMessageJob do
  subject(:perform) { described_class.perform_now(webhook_message) }

  context "with a trn_request.completed message" do
    let(:webhook_message) { create(:trs_webhook_message, :trn_request_completed) }
    let(:processor) { instance_double(Trs::TrnRequestCompletedProcessor, call: nil) }

    before { allow(Trs::TrnRequestCompletedProcessor).to receive(:new).with(webhook_message).and_return(processor) }

    it "runs the TRN request completed processor" do
      perform

      expect(processor).to have_received(:call)
    end
  end

  context "with a ping message" do
    let(:webhook_message) { create(:trs_webhook_message, message: { "pingId" => "ping-123" }) }

    it "marks the message as processed, recording the ping ID" do
      perform

      expect(webhook_message.reload).to have_attributes(status: "processed", status_comment: "pingId: ping-123")
    end
  end

  context "with an unhandled message type" do
    let(:webhook_message) { create(:trs_webhook_message, message_type: "alert.created") }

    it "marks the message as ignored" do
      perform

      expect(webhook_message.reload).to have_attributes(status: "ignored", status_comment: "No processor for message type alert.created")
    end

    it "reports to Sentry" do
      allow(Sentry).to receive(:capture_message)

      perform

      expect(Sentry).to have_received(:capture_message).with("[TRS webhook] No processor for message type alert.created", hash_including(level: :warning))
    end
  end

  context "when the message has already been processed" do
    let(:webhook_message) { create(:trs_webhook_message, status: :processed, status_comment: "done") }

    it "does not process it again" do
      expect { perform }.not_to(change { webhook_message.reload.attributes })
    end
  end
end
