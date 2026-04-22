require "rails_helper"

RSpec.describe Crons::SendDeferralExpiringNotificationEmailsJob, type: :job do
  describe "#perform" do
    let(:application) { create(:application, :deferred) }

    it "enqueues email for deferrals at 11 months" do
      application.state_changes.last.update!(created_at: 11.months.ago)

      expect { described_class.perform_now }
        .to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
    end

    it "skips recent deferrals" do
      application.state_changes.last.update!(created_at: 2.months.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
    end

    it "skips already notified applications" do
      application.state_changes.last.update!(created_at: 11.months.ago)
      create(:notification, application:, event: "deferral_expiring_notification", created_at: 10.months.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
    end

    it "re-notifies after a new deferral" do
      application.state_changes.last.update!(created_at: 11.months.ago)
      create(:notification, application:, event: "deferral_expiring_notification", created_at: 2.years.ago)

      expect { described_class.perform_now }
        .to have_enqueued_mail(GenericMailer, :deferral_expiring_notification)
    end
  end
end
