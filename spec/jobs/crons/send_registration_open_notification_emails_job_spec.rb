require "rails_helper"

RSpec.describe Crons::SendRegistrationOpenNotificationEmailsJob, type: :job do
  describe "#perform" do
    let(:cohort) { create(:cohort, registration_starts_at: Time.zone.yesterday) }
    let(:application_cohort) do
      create(
        :cohort,
        registration_starts_at: Time.zone.yesterday.prev_year,
      )
    end
    let(:course_cohort) { create(:course_cohort, course: Course.last, cohort: application_cohort) }
    let(:application) do
      create(
        :application,
        :deferred,
        course_cohort:,
        schedule: create(:schedule, cohort: application_cohort),
      )
    end

    before { create(:course_cohort, cohort:, course: application.course) }

    it "enqueues email for deferred applications when registration opened yesterday" do
      expect { described_class.perform_now }
        .to have_enqueued_mail(GenericMailer, :registration_open_notification)
    end

    it "records a notification event for the cohort and course" do
      perform_enqueued_jobs { described_class.perform_now }

      notification = application.notifications.find_by!(event: "registration_open_notification")

      expect(notification.metadata).to include(
        "cohort_id" => cohort.id,
        "course_id" => application.course.id,
      )
    end

    it "skips deferred applications whose course is not on the cohort" do
      other_course = build(:course, identifier: "another-course")
      other_course.save!
      other_cohort = create(:cohort, registration_starts_at: Date.new(2024, 5, 1))

      create(
        :application,
        :deferred,
        course: other_course,
        cohort: other_cohort,
        schedule: create(:schedule, cohort: other_cohort),
      )

      expect { described_class.perform_now }
        .to have_enqueued_mail(GenericMailer, :registration_open_notification).once
    end

    it "skips applications that have already been notified for this cohort" do
      application.notifications.create!(
        event: "registration_open_notification",
        metadata: {
          "cohort_id" => cohort.id,
          "course_id" => application.course.id,
        },
      )

      expect { described_class.perform_now }
        .not_to have_enqueued_mail(GenericMailer, :registration_open_notification)
    end

    it "does not treat a notification for another course as already sent" do
      application.notifications.create!(
        event: "registration_open_notification",
        metadata: {
          "cohort_id" => cohort.id,
          "course_id" => -1,
        },
      )

      expect { described_class.perform_now }
        .to have_enqueued_mail(GenericMailer, :registration_open_notification)
    end

    it "skips cohorts where registration did not open yesterday" do
      cohort.update!(registration_starts_at: Time.zone.today)

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
