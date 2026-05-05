module Emails
  class SendApplicationSubmissionEmailJob < ApplicationJob
    queue_as :default

    def perform(application:)
      GenericMailer.with(
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.localise_sentence_embedded_course_name,
        amount: application.raw_application_data["funding_amount"],
        ecf_id: application.ecf_id,
      ).application_submitted.deliver_now
    end
  end
end
