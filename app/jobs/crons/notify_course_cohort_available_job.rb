class Crons::NotifyCourseCohortAvailableJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 6 * * *"

  sentry_monitor_check_ins slug: "notify-course-cohort-available"

  def perform
    CourseCohort
      .includes(:course, :cohort)
      .where(cohort: { registration_starts_at: Date.current })
      .find_each do |course_cohort|
      User.where(email_updates_status: User::EMAIL_NPD_REGISTRATION_OPEN).find_each do |user|
        GenericMailer.with(
          to: user.email,
          course_name: course_cohort.course.name,
          course_group: I18n.t("course_group.#{course_cohort.course.course_group}"),
          training_date: course_cohort.training_starts_at.to_fs(:govuk_approx),
          application_link: Rails.application.routes.url_helpers.registration_wizard_show_url(:start),
          unsubscribe_link: Rails.application.routes.url_helpers.unsubscribe_email_updates_url,
        ).notify_course_cohort_available.deliver_later
      end
    end
  end
end
