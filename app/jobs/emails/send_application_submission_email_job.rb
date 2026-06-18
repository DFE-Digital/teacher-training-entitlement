module Emails
  class SendApplicationSubmissionEmailJob < ApplicationJob
    queue_as :default

    def perform(application:)
      GenericMailer.with(
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.name,
        cohort_date: application.cohort.name,
        ecf_id: application.ecf_id,
        sign_in_link: Rails.configuration.sign_in_link,
        feedback_link: Rails.configuration.feedback_link,
      ).application_submitted.deliver_now
    end
  end
end
