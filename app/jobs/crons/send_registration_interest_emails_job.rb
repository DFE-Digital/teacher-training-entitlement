module Crons
  class SendRegistrationInterestEmailsJob < CronJob
    include Sentry::Cron::MonitorCheckIns
    include Rails.application.routes.url_helpers

    self.cron_expression = "0 11 * * *"

    sentry_monitor_check_ins slug: "send-registration-interest-emails"

    def perform
      return if Feature.registration_disabled?
      return unless Cohort.where(registration_starts_at: Time.zone.today).exists?

      RegistrationInterest.not_yet_notified.find_each do |registration_interest|
        GenericMailer.with(
          to: registration_interest.email,
          registration_start_url: registration_wizard_show_url(:start),
        ).registration_interest.deliver_later

        registration_interest.update!(notified: true)
      end
    end
  end
end
