class ApplicationSubmissionMailer < GenericMailer
  def application_submitted_mail(to:, full_name:, provider_name:, course_name:, amount:, ecf_id:)
    body = <<~TEXT\
      Your application has been submitted.
      Full name: #{full_name}
      Provider name: #{provider_name}
      Course name: #{course_name}
      Amount: #{amount}
      ECF ID: #{ecf_id}
    TEXT

    build_generic_email(to:, subject: "Application submitted", body:)
  end
end
