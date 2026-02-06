class ApplicationFundingEligibilityMailer < GenericMailer
  def eligible_for_funding_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
    body = <<~TEXT
      Your application has been assessed as eligible for funding.
      Full name: #{full_name}
      Provider name: #{provider_name}
      Course name: #{course_name}
      ECF ID: #{ecf_id}
    TEXT

    build_generic_email(to:, subject: "Eligible for funding", body:)
  end
end
