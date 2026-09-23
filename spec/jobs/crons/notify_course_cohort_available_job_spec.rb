require "rails_helper"

RSpec.describe Crons::NotifyCourseCohortAvailableJob, type: :job do
  describe "#perform" do
    before do
      cc = create(:course_cohort)
      cc.cohort.update!(registration_starts_at: Date.current)
    end

    context "when user is registered for npd notification" do
      before do
        create(:user, email_updates_status: User::EMAIL_NPD_REGISTRATION_OPEN)
      end

      it "enqueues notification email" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(GenericMailer, :notify_course_cohort_available)
      end
    end

    context "when user is not registered for any notification" do
      before do
        create(:user, email_updates_status: nil)
      end

      it "does not enqueues notification email" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(GenericMailer, :notify_course_cohort_available)
      end
    end
  end
end
