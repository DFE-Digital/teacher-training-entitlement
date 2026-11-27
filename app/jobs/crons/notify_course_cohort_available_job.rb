class Crons::NotifyCourseCohortAvailableJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 6 * * *"

  sentry_monitor_check_ins slug: "notify-course-cohort-available"

  def perform
    # Job specific to NPD early years course
    course_cohort = CourseCohort
                      .includes(:course, :cohort)
                      .find_by(
                        course: { identifier: Course::TTE_EARLY_YEARS },
                        cohort: { registration_starts_at: Date.current },
                      )

    return unless course_cohort

    EmailUpdateSubscription.npd_registration_open_status.find_each do |subscription|
      GenericMailer.with(
        to: subscription.email,
        course_name: course_cohort.course.name,
        course_group: I18n.t("course_group.#{course_cohort.course.course_group}"),
        training_date: course_cohort.training_starts_at.to_fs(:govuk_approx),
        application_link: Rails.application.routes.url_helpers.registration_wizard_show_url(:start),
        unsubscribe_link: Rails.application.routes.url_helpers.unsubscribe_email_updates_url(unsubscribe_key: subscription.unsubscribe_key),
      ).notify_course_cohort_available.deliver_later
    end
  end
end
