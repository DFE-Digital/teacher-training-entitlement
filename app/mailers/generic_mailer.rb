class GenericMailer < ApplicationMailer
  TEMPLATE_ID = "a586a2a2-f53a-4201-a489-e7aaf09ec1d9".freeze

  after_action :log_application_event, if: :application

  def eligible_for_funding
    generic_mail(subject: "mailers.eligible_for_funding")
  end

  def application_submitted
    generic_mail(subject: "mailers.application_submitted")
  end

  def confirmation_code
    generic_mail(subject: "mailers.confirmation_code")
  end

  def email_updates_confirmation
    generic_mail(subject: "mailers.email_updates_confirmation")
  end

  def change_provider
    generic_mail(subject: "mailers.change_provider")
  end

private

  def generic_mail(subject:)
    view_mail(TEMPLATE_ID, to: params[:to], subject: I18n.t(subject))
  end

private

  def application
    @application ||= Application.find_by(ecf_id: params[:ecf_id]) if params[:ecf_id].present?
  end

  def log_application_event
    return unless application

    application.notifications.create!(
      event: action_name,
      metadata: { recipient: params[:to] },
    )
  end
end
