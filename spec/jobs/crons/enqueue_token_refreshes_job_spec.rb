require "rails_helper"

RSpec.describe Crons::EnqueueTokenRefreshesJob, type: :job do
  describe "#perform" do
    it "enqueues RefreshTeacherTokenJob for teachers needing token refresh" do
      teacher = create(:teacher, trn: nil, refresh_token: "token", refresh_token_updated_at: 2.days.ago)

      expect { described_class.perform_now }.to have_enqueued_job(RefreshTeacherTokenJob).with(teacher)
    end

    it "does not enqueue jobs for teachers with TRN" do
      create(:teacher, trn: "1234567", refresh_token: "token", refresh_token_updated_at: 2.days.ago)

      expect { described_class.perform_now }.not_to have_enqueued_job(RefreshTeacherTokenJob)
    end

    it "does not enqueue jobs for teachers with recent refresh" do
      create(:teacher, trn: nil, refresh_token: "token", refresh_token_updated_at: 1.hour.ago)

      expect { described_class.perform_now }.not_to have_enqueued_job(RefreshTeacherTokenJob)
    end
  end
end
