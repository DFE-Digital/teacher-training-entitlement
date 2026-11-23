class Crons::EnqueueTokenRefreshesJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 * * * *"

  sentry_monitor_check_ins slug: "enqueue-token-refreshes"

  def perform
    Teacher.requiring_token_refresh.find_each do |teacher|
      RefreshTeacherTokenJob.perform_later(teacher)
    end
  end
end
