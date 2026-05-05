class Crons::SendRegistrationOpenNotificationEmailsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 6 * * *"

  sentry_monitor_check_ins slug: "send-registration-open-notification-emails"

  def perform
    Cohort.where(registration_starts_at: Date.yesterday).find_each do |cohort|
      Application.deferred_status.find_each do |application|
        next if already_notified?(application, cohort)

        GenericMailer.with(
          to: application.user.email,
          full_name: application.user.full_name,
          course_name: application.course.title_embedded_course_name,
          next_course_start_date: cohort.registration_starts_at.to_fs(:govuk),
          deferral_date: application.deferred_at.to_fs(:govuk_date_only),
          ecf_id: application.ecf_id,
          cohort_id: cohort.id,
        ).registration_open_notification.deliver_later
      end
    end
  end

private

  def already_notified?(application, cohort)
    application.notifications
               .where(event: "registration_open_notification")
               .where("metadata->>'cohort_id' = ?", cohort.id.to_s)
               .exists?
  end
end
