class GenericMailerPreview < ActionMailer::Preview
  def eligible_for_funding
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      provider_name: "Ambition Institute",
      course_name: "TTE Course",
      ecf_id: "abc-123-def-456",
    ).eligible_for_funding
  end

  def application_submitted
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      provider_name: "Ambition Institute",
      course_name: "TTE Course",
      amount: "£1,200",
      ecf_id: "abc-123-def-456",
    ).application_submitted
  end

  def confirmation_code
    GenericMailer.with(
      to: "test@example.com",
      code: "abc123",
    ).confirmation_code
  end

  def email_updates_confirmation
    GenericMailer.with(
      to: "test@example.com",
      service_link: "https://example.service.gov.uk",
      unsubscribe_link: "https://example.service.gov.uk/unsubscribe?token=abc123",
    ).email_updates_confirmation
  end

  def deferral_notification
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      provider_name: "Ambition Institute",
      course_name: "Early Years TTE",
      deferral_date: "10 November 2026",
      ecf_id: "abc-123-def-456",
    ).deferral_notification
  end
end
