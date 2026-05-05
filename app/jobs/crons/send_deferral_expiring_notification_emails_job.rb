class Crons::SendDeferralExpiringNotificationEmailsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  DEFERRAL_WARNING_MONTHS = 11

  # run at 6:15 AM every day
  self.cron_expression = "15 6 * * *"

  sentry_monitor_check_ins slug: "send-deferral-expiring-notification-emails"

  def perform
    eligible_applications.find_each do |application|
      GenericMailer.with(
        to: application.user.email,
        full_name: application.user.full_name,
        course_name: application.course.title_embedded_course_name,
        deferral_date: application.deferred_at.to_fs(:govuk_date_only),
        ecf_id: application.ecf_id,
      ).deferral_expiring_notification.deliver_later
    end
  end

private

  def eligible_applications
    Application
      .deferred_status
      .where(id: StateChange.deferred(months: DEFERRAL_WARNING_MONTHS))
      .where.not(id: already_notified_application_ids)
  end

  def already_notified_application_ids
    # Only exclude if notification was sent AFTER their most recent deferral
    # (allows re-notification if they defer again after resuming)
    Notification
      .where(event: "deferral_expiring_notification")
      .joins("INNER JOIN (#{StateChange.most_recent_deferrals.to_sql}) recent_deferrals ON application_events.application_id = recent_deferrals.application_id")
      .where("application_events.created_at > recent_deferrals.last_deferral_at")
      .select(:application_id)
  end
end
