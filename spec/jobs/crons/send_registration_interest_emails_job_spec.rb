require "rails_helper"

RSpec.describe Crons::SendRegistrationInterestEmailsJob, type: :job do
  describe "#perform" do
    context "when registration opens today" do
      before { create(:cohort, start_year: Time.zone.today.year, registration_starts_at: Time.zone.today) }

      context "when registration is disabled" do
        before { Feature.disable_registration! }

        it "does not enqueue registration interest emails" do
          create(:registration_interest)

          expect { described_class.perform_now }
            .not_to have_enqueued_mail(GenericMailer, :registration_interest)
        end

        it "leaves the registration interest as not notified" do
          registration_interest = create(:registration_interest)

          expect { described_class.perform_now }
            .not_to(change { registration_interest.reload.notified })
        end
      end

      it "enqueues registration interest emails" do
        create(:registration_interest)

        expect { described_class.perform_now }
          .to have_enqueued_mail(GenericMailer, :registration_interest)
      end

      it "includes the full registration start URL" do
        create(:registration_interest)

        described_class.perform_now

        expect(enqueued_jobs.last[:args].last["params"]["registration_start_url"])
          .to eq(Rails.application.routes.url_helpers.registration_wizard_show_url(:start))
      end

      it "marks the registration interest as notified" do
        registration_interest = create(:registration_interest)

        expect { described_class.perform_now }
          .to change { registration_interest.reload.notified }
          .from(false)
          .to(true)
      end

      it "does not email registration interests already notified" do
        create(:registration_interest, :notified)

        expect { described_class.perform_now }
          .not_to have_enqueued_mail(GenericMailer, :registration_interest)
      end
    end

    context "when registration does not open today" do
      before { create(:cohort, start_year: Time.zone.yesterday.year, registration_starts_at: Time.zone.yesterday) }

      it "does not enqueue registration interest emails" do
        create(:registration_interest)

        expect { described_class.perform_now }
          .not_to have_enqueued_mail(GenericMailer, :registration_interest)
      end

      it "leaves the registration interest as not notified" do
        registration_interest = create(:registration_interest)

        expect { described_class.perform_now }
          .not_to(change { registration_interest.reload.notified })
      end
    end

    it "runs at 11am each day" do
      expect(described_class.cron_expression).to eq("0 11 * * *")
    end
  end
end
