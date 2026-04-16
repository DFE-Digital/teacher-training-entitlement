require "rails_helper"

RSpec.describe Crons::ExpireDeferredApplicationsJob do
  describe "#schedule" do
    it "enqueues job" do
      expect {
        described_class.schedule
      }.to have_enqueued_job
    end
  end

  describe "#perform" do
    let(:application) { create(:application, :deferred) }
    let(:withdraw_service) { instance_double(Applications::Withdraw, call: true) }

    before do
      allow(Applications::Withdraw).to receive(:new).and_return(withdraw_service)
    end

    context "when application has been deferred for more than 14 months" do
      before do
        application.state_changes.find_by(event: Application::DEFERRED).update!(created_at: 15.months.ago)
      end

      it "calls the withdraw service with the correct arguments" do
        described_class.perform_now

        expect(Applications::Withdraw).to have_received(:new).with(
          application:,
          reason: "deferred-for-over-12-months",
        )
        expect(withdraw_service).to have_received(:call)
      end
    end

    context "when application has been deferred for less than 14 months" do
      before do
        application.state_changes.find_by(event: Application::DEFERRED).update!(created_at: 13.months.ago)
      end

      it "does not call the withdraw service" do
        described_class.perform_now

        expect(Applications::Withdraw).not_to have_received(:new)
      end
    end

    context "when application is not deferred" do
      let(:application) { create(:application, :accepted) }

      it "does not call the withdraw service" do
        described_class.perform_now

        expect(Applications::Withdraw).not_to have_received(:new)
      end
    end

    context "when application was deferred, resumed, then deferred again recently" do
      let(:application) { create(:application, :started) }

      before do
        # First deferral 16 months ago
        application.state_changes.create!(event: Application::DEFERRED, created_at: 16.months.ago)
        # Resumed
        application.state_changes.create!(event: Application::STARTED, created_at: 10.months.ago)
        # Second deferral 2 months ago
        application.state_changes.create!(event: Application::DEFERRED, created_at: 2.months.ago)
        application.update!(status: "deferred")
      end

      it "does not call the withdraw service because the most recent deferral is recent" do
        described_class.perform_now

        expect(Applications::Withdraw).not_to have_received(:new)
      end
    end
  end
end
