class ConfirmEmailMailer < GenericMailer
  def confirmation_code_mail(to:, code:)
    body = <<~TEXT
      Your confirmation code is #{code}.
      It will expire in 10 minutes.
    TEXT

    build_generic_email(to:, subject: "Confirmation Code", body:, personalisation: { code: })
  end
end
