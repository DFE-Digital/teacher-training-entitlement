class GenericMailer < ApplicationMailer
  TEMPLATE_ID = "a586a2a2-f53a-4201-a489-e7aaf09ec1d9".freeze

protected

  def build_generic_email(to:, subject:, body:, personalisation: {})
    personalisation.merge!(subject:,
                           body:)
    template_mail(TEMPLATE_ID,
                  to:,
                  personalisation:)
  end
end
