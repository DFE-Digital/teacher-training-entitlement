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
        application.application_states.find_by(status: "deferred").update!(created_at: 15.months.ago)
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
        application.application_states.find_by(status: "deferred").update!(created_at: 13.months.ago)
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
  end
end
