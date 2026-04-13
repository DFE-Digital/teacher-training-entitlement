class Crons::ExpireDeferredApplicationsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  DEFERRAL_EXPIRY_MONTHS = 14

  # run at 4:00 AM every day
  self.cron_expression = "0 4 * * *"

  sentry_monitor_check_ins slug: "expire-deferred-applications"

  def perform
    expired_deferred_applications.find_each do |application|
      Applications::Withdraw.new(
        application:,
        reason: "deferred-for-over-12-months",
      ).call
    end
  end

private

  # Ordinarily, an application would only be deferred once,
  # but we need to handle the edge case where an application is:
  # 1. Deferred 16 months ago
  # 2. Resumed
  # 3. Deferred again 2 months ago
  def expired_deferred_applications
    Application
      .includes(:application_events)
      .deferred_status
      .where(
        "id IN (
          SELECT application_id FROM application_events
          WHERE event = ?
          GROUP BY application_id
          HAVING MAX(created_at) < ?
        )",
        "StateChange::Application::DEFERRED",
        DEFERRAL_EXPIRY_MONTHS.months.ago,
      )
  end
end
