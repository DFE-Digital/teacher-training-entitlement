require "rails_helper"

RSpec.describe Crons::SendRegistrationOpenNotificationEmailsJob, type: :job do
  describe "#perform" do
    let(:cohort) { create(:cohort, start_year: Date.yesterday.year, registration_starts_at: Date.yesterday) }
    let(:application) { create(:application, status: Application::DEFERRED) }

    it "enqueues email for deferred applications when registration opened yesterday" do
      cohort
      application

      expect { described_class.perform_now }
        .to have_enqueued_mail(GenericMailer, :registration_open_notification)
    end

    it "skips applications that have already been notified for this cohort" do
      application.notifications.create!(
        event: "registration_open_notification",
        metadata: { "cohort_id" => cohort.id },
      )

      expect { described_class.perform_now }
        .not_to have_enqueued_mail(GenericMailer, :registration_open_notification)
    end

    it "skips cohorts where registration did not open yesterday" do
      cohort.update!(registration_starts_at: Date.current)

      expect { described_class.perform_now }
        .not_to have_enqueued_mail(GenericMailer, :registration_open_notification)
    end

    it "skips non-deferred applications" do
      application.update!(status: Application::STARTED)

      expect { described_class.perform_now }
        .not_to have_enqueued_mail(GenericMailer, :registration_open_notification)
    end
  end
end
