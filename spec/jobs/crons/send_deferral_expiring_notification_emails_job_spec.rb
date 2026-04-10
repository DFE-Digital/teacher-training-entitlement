require "rails_helper"

RSpec.describe Crons::SendDeferralExpiringNotificationEmailsJob, type: :job do
  describe "#perform" do
    let(:application) { create(:application, :deferred) }

    before do
      application.state_changes.last.update!(created_at: 11.months.ago)
    end

    it "enqueues email for expiring deferrals" do
      expect { described_class.perform_now }
        .to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
    end

    context "when deferral is too recent" do
      before do
        application.state_changes.last.update!(created_at: 2.months.ago)
      end

      it "does not enqueue email" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
      end
    end

    context "when already notified after current deferral" do
      before do
        create(:notification, application:, event: "deferral_expiring_notification", created_at: 10.months.ago)
      end

      it "does not enqueue email" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
      end
    end

    context "when notified before current deferral (re-deferral scenario)" do
      before do
        # Notification from a previous deferral cycle
        create(:notification, application:, event: "deferral_expiring_notification", created_at: 2.years.ago)
      end

      it "enqueues email for the new deferral" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
      end
    end
  end
end
