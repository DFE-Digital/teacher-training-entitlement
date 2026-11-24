class Crons::EnqueueTrnActivationChecksJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 6 * * *"

  sentry_monitor_check_ins slug: "enqueue-trn-activation-checks"

  def perform
    Teacher.needing_trn_activation_check.find_each do |teacher|
      RequestTrnJob.perform_later(teacher)
    end
  end
end
