require "rails_helper"

RSpec.describe Trs::TrnRequestCompletedProcessor do
  subject(:process) { described_class.new(webhook_message).call }

  let(:user) do
    create(
      :user,
      :with_one_login_id,
      trn: nil,
      refresh_token: "refresh-token",
      refresh_token_updated_at: 1.hour.ago,
      trn_requested_at: 1.day.ago,
    )
  end

  let(:webhook_message) do
    create(
      :trs_webhook_message,
      :trn_request_completed,
      one_login_id: user.one_login_id,
      trn: "7654321",
    )
  end

  it "sets the TRN and clears the refresh token" do
    process

    expect(user.reload).to have_attributes(trn: "7654321", refresh_token: nil, refresh_token_updated_at: nil)
  end

  it "marks the message as processed" do
    process

    expect(webhook_message.reload).to have_attributes(status: "processed", processed_at: be_present)
  end

  it "takes the user out of the TRN activation polling" do
    expect { process }.to change { User.needing_trn_activation_check.include?(user) }.from(true).to(false)
  end

  context "when another user already has the TRN" do
    let!(:other_user) { create(:user, trn: "7654321") }
    let!(:other_application) { create(:application, user: other_user) }

    it "merges the other user into this one" do
      process

      expect(other_user.reload).to be_archived
      expect(other_application.reload.user).to eq(user)
    end
  end

  shared_examples "a failed message" do |comment|
    it "marks the message as failed without changing the user" do
      expect { process }.not_to(change { user.reload.attributes })

      expect(webhook_message.reload).to have_attributes(status: "failed", status_comment: comment)
    end

    it "reports to Sentry" do
      allow(Sentry).to receive(:capture_message)

      process

      expect(Sentry).to have_received(:capture_message).with("[TRS webhook] #{comment}", anything)
    end
  end

  context "when no user has the One Login ID" do
    let(:webhook_message) do
      create(
        :trs_webhook_message,
        :trn_request_completed,
        one_login_id: "unknown",
        trn: "7654321",
      )
    end

    it_behaves_like "a failed message", "No user found with this One Login ID"
  end

  context "when the message has no TRN" do
    let(:webhook_message) do
      create(
        :trs_webhook_message,
        :trn_request_completed,
        one_login_id: user.one_login_id,
        trn: nil,
      )
    end

    it_behaves_like "a failed message", "Message has no trnRequest.trn"
  end

  context "when the message has no One Login subject" do
    let(:webhook_message) do
      create(
        :trs_webhook_message,
        :trn_request_completed,
        one_login_id: nil,
      )
    end

    it_behaves_like "a failed message", "Message has no trnRequest.oneLoginUserSubject"
  end
end
