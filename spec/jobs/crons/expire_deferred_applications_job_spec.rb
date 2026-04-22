require "rails_helper"

RSpec.describe Crons::ExpireDeferredApplicationsJob, type: :job do
  describe "#perform" do
    let(:application) { create(:application, :deferred) }
    let(:withdraw_service) { instance_double(Applications::Withdraw, call: true) }

    before do
      allow(Applications::Withdraw).to receive(:new).and_return(withdraw_service)
    end

    it "withdraws applications deferred for more than 14 months" do
      application.state_changes.last.update!(created_at: 15.months.ago)

      described_class.perform_now

      expect(Applications::Withdraw).to have_received(:new).with(
        application:,
        reason: "deferred-for-over-12-months",
      )
    end

    it "skips applications deferred for less than 14 months" do
      application.state_changes.last.update!(created_at: 13.months.ago)

      described_class.perform_now

      expect(Applications::Withdraw).not_to have_received(:new)
    end

    it "uses most recent deferral date for re-deferred applications" do
      application.state_changes.last.update!(created_at: 16.months.ago)
      application.state_changes.create!(event: Application::STARTED, created_at: 10.months.ago)
      application.state_changes.create!(event: Application::DEFERRED, created_at: 2.months.ago)

      described_class.perform_now

      expect(Applications::Withdraw).not_to have_received(:new)
    end
  end
end
