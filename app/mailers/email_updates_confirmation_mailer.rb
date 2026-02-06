class EmailUpdatesConfirmationMailer < GenericMailer
  TEMPLATE_ID = "9cce029e-1d43-40ee-8664-2657fc22b1eb".freeze

  def email_updates_confirmation_mail(to:, service_link:, unsubscribe_link:)
    body = <<~TEXT
      Your service link  #{service_link}.
      You can unsubscribe from this service using the following link: #{unsubscribe_link}.
    TEXT

    build_generic_email(to:, subject: "Email Updates Confirmation", body:)
  end
end
