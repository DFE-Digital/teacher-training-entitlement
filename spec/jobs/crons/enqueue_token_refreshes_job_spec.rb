require "rails_helper"

RSpec.describe Crons::EnqueueTokenRefreshesJob, type: :job do
  describe "#perform" do
    it "enqueues RefreshUserTokenJob for users needing token refresh" do
      user = create(:user, trn: nil, refresh_token: "token", refresh_token_updated_at: 2.days.ago)

      expect { described_class.perform_now }.to have_enqueued_job(RefreshUserTokenJob).with(user)
    end

    it "does not enqueue jobs for users with TRN" do
      create(:user, trn: "1234567", refresh_token: "token", refresh_token_updated_at: 2.days.ago)

      expect { described_class.perform_now }.not_to have_enqueued_job(RefreshUserTokenJob)
    end

    it "does not enqueue jobs for users with recent refresh" do
      create(:user, trn: nil, refresh_token: "token", refresh_token_updated_at: 1.hour.ago)

      expect { described_class.perform_now }.not_to have_enqueued_job(RefreshUserTokenJob)
    end
  end
end
