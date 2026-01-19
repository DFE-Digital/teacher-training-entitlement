class ApplicationSubmissionMailer < ApplicationMailer
  TEMPLATE_ID = "a586a2a2-f53a-4201-a489-e7aaf09ec1d9".freeze

  def application_submitted_mail(_template_id, to:, full_name:, provider_name:, course_name:, amount:, ecf_id:)
    template_mail(TEMPLATE_ID,
                  to:,
                  personalisation: {
                    full_name:,
                    provider_name:,
                    course_name:,
                    amount:,
                    ecf_id:,
                  })
  end
end
