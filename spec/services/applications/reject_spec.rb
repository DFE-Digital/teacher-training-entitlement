require "rails_helper"

RSpec.describe Applications::Reject, type: :model do
  include ActiveJob::TestHelper

  subject(:service) { described_class.new(application:, reason_for_rejection:) }

  let(:reason_for_rejection) { Application.reason_for_rejections[:rejected_by_provider] }

  describe "validations" do
    let(:application) { build(:application, :pending) }

    it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }
    it { is_expected.to validate_presence_of(:reason_for_rejection).with_message("The reason_for_rejection cannot be blank.") }

    context "when application is rejected" do
      let(:application) { build(:application, :rejected) }

      it { is_expected.to have_error(:application, :has_already_been_rejected, "This application has already been rejected") }
    end

    %i[accepted started completed deferred withdrawn].each do |state|
      context "when application is #{state}" do
        let(:application) { build(:application, state) }

        it { is_expected.to have_error(:application, :has_already_been_accepted), "This application has already been accepted" }
      end
    end

    context "when application not rejectable" do
      let(:application) { build(:application, funded_place: 1) }

      it { is_expected.to have_error(:application, :not_rejectable) }
    end
  end

  describe ".reject" do
    let(:application) { create(:application, :pending) }

    it "marks the status as rejected" do
      expect { service.call }.to change { application.reload.status }.from(Application::PENDING).to(Application::REJECTED)
    end

    it "reloads application after action" do
      allow(service.application).to receive(:reload)
      service.call
      expect(service.application).to have_received(:reload)
    end

    it "sets the reason for rejection" do
      expect { service.call }.to change { application.reload.reason_for_rejection }.from(nil).to(reason_for_rejection)
    end

    context "when reason is rejected_by_provider" do
      let(:reason_for_rejection) { Application.reason_for_rejections[:rejected_by_provider] }

      it "enqueues a provider rejection email" do
        service.reject
        expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with("GenericMailer", "provider_rejected", "deliver_now", anything)
      end
    end

    context "when reason is not rejected_by_provider" do
      let(:reason_for_rejection) { Application.reason_for_rejections[:registration_expired] }

      it "does not enqueue a provider rejection email" do
        service.reject
        expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued.with("GenericMailer", "provider_rejected", "deliver_now", anything)
      end
    end
  end
end
