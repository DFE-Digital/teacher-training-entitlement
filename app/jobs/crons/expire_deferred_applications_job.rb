class Crons::ExpireDeferredApplicationsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

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

  def expired_deferred_applications
    Application
      .deferred_status
      .where(id: StateChange.expired_deferrals)
  end
end
