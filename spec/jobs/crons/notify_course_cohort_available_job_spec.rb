require "rails_helper"

RSpec.describe Crons::NotifyCourseCohortAvailableJob, type: :job do
  describe "#perform" do
    before do
      cc = create(:course_cohort)
      cc.cohort.update!(registration_starts_at: Date.current)
    end

    context "when someone is subscribed to npd notifications" do
      let!(:subscription) { create(:email_update_subscription) }

      it "enqueues notification email" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(GenericMailer, :notify_course_cohort_available)
          .with(a_hash_including(params: a_hash_including(to: subscription.email)))
      end
    end

    context "when nobody is subscribed to notifications" do
      it "does not enqueues notification email" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(GenericMailer, :notify_course_cohort_available)
      end
    end
  end
end
