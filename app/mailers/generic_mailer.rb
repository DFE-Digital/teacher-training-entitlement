class GenericMailer < ApplicationMailer
  TEMPLATE_ID = "a586a2a2-f53a-4201-a489-e7aaf09ec1d9".freeze

  after_action :log_application_event, if: :application

  def eligible_for_funding
    view_mail(TEMPLATE_ID, to: params[:to], subject: "Eligible for funding")
  end

  def application_submitted
    view_mail(TEMPLATE_ID, to: params[:to], subject: "Application submitted")
  end

  def confirmation_code
    view_mail(TEMPLATE_ID, to: params[:to], subject: "Confirmation Code")
  end

  def email_updates_confirmation
    view_mail(TEMPLATE_ID, to: params[:to], subject: "Email Updates Confirmation")
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
