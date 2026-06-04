require "rails_helper"

RSpec.describe Crons::EnqueueTrnActivationChecksJob, type: :job do
  describe "#perform" do
    it "enqueues RequestTrnJob only for users needing TRN activation check" do
      create(:user, trn: nil, refresh_token: "token", trn_requested_at: 1.day.ago)
      create(:user, trn: "1234567")

      expect { described_class.perform_now }.to have_enqueued_job(RequestTrnJob).once
    end
  end
end
