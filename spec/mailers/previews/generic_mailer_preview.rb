class GenericMailerPreview < ActionMailer::Preview
  def application_submitted
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      provider_name: "Ambition Institute",
      course_name: "Teaching in Reception",
      cohort_date: "autumn 2026",
      ecf_id: "abc-123-def-456",
      sign_in_link: "https://national-professional-development.education.gov.uk/",
      feedback_link: "https://forms.cloud.microsoft/e/hWuJx59U2P",
    ).application_submitted
  end

  def change_provider
    GenericMailer.with(
      to: "test@example.com",
      ecf_id: "abcd-1234-efgh-5678-ijkl",
      full_name: "Dave Coaches",
      course_name: "Teaching in Reception",
      cohort_date: "Autumn 2026",
      provider_name: "Acme Teaching",
      sign_in_link: "https://national-professional-development.education.gov.uk/",
      feedback_link: "https://forms.cloud.microsoft/e/hWuJx59U2P",
    ).change_provider
  end

  def confirmation_code
    GenericMailer.with(
      to: "test@example.com",
      code: "abc123",
    ).confirmation_code
  end

  def deferral_expiring_notification
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      course_name: "Excellence in reception teaching",
      deferral_date: 11.months.ago.to_fs(:govuk_date_only),
      ecf_id: "abc-123-def-456",
    ).deferral_expiring_notification
  end

  def deferral_notification
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      provider_name: "Ambition Institute",
      course_name: "Excellence in reception teaching",
      deferral_date: Date.current.to_fs(:govuk),
      ecf_id: "abc-123-def-456",
    ).deferral_notification
  end

  def eligible_for_funding
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      provider_name: "Ambition Institute",
      course_name: "TTE Course",
      ecf_id: "abc-123-def-456",
    ).eligible_for_funding
  end

  def email_updates_confirmation
    GenericMailer.with(
      to: "test@example.com",
      service_link: "https://example.service.gov.uk",
      unsubscribe_link: "https://example.service.gov.uk/unsubscribe?token=abc123",
    ).email_updates_confirmation
  end

  def registration_open_notification
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      course_name: "Excellence in reception teaching",
      next_course_start_date: Date.current.to_fs(:govuk),
      deferral_date: 3.months.ago.to_fs(:govuk_date_only),
      ecf_id: "abc-123-def-456",
    ).registration_open_notification
  end

  def registration_interest
    GenericMailer.with(
      to: "test@example.com",
      registration_start_url: Rails.application.routes.url_helpers.registration_wizard_show_url(:start),
    ).registration_interest
  end

  def provider_rejected
    GenericMailer.with(
      to: "test@example.com",
      full_name: "Jane Smith",
      course_name: "Excellence in reception teaching",
      provider_name: "Ambition Institute",
      cohort_date: "Autumn 2026",
      sign_in_link: "https://national-professional-development.education.gov.uk/",
      ecf_id: "abc-123-def-456",
    ).provider_rejected
  end

  def previous_provider
    GenericMailer.with(
      to: "test@example.com",
      provider_name: LeadProvider.first.name,
      course_name: "Teaching in Reception",
      participant_trn: nil,
      particitpant_name: "Tobias Harris",
      change_date: "13 May 2026 14:00",
      ecf_id: "abcd-1234-efgh-5678-ijkl",
    ).previous_provider
  end
end
