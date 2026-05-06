# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crons::EnqueueTokenRefreshesJob, type: :job do
  describe "#perform" do
    it "enqueues RefreshUserTokenJob for users needing token refresh" do
      user = create(:user, trn: nil, refresh_token: "token", refresh_token_updated_at: 8.days.ago)

      expect(RefreshUserTokenJob).to receive(:perform_later).with(user)

      described_class.perform_now
    end

    it "does not enqueue jobs for users with TRN" do
      create(:user, trn: "1234567", refresh_token: "token", refresh_token_updated_at: 8.days.ago)

      expect(RefreshUserTokenJob).not_to receive(:perform_later)

      described_class.perform_now
    end
  end
end
