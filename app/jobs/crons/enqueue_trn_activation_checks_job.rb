class Crons::EnqueueTrnActivationChecksJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 6 * * *"

  sentry_monitor_check_ins slug: "enqueue-trn-activation-checks"

  def perform
    User.needing_trn_activation_check.find_each do |user|
      RequestTrnJob.perform_later(user)
    end
  end
end
