class EmailUpdatesController < PublicPagesController
  before_action only: %i[create] do
    redirect_to root_path unless current_teacher&.persisted?
  end

  def create
    current_teacher.update!(email_updates_status: Teacher::EMAIL_NPD_REGISTRATION_OPEN)

    GenericMailer.with(
      to: current_teacher.email,
      name: current_teacher.full_name,
      unsubscribe_link:,
    ).email_updates_confirmation.deliver_later
  end

  def unsubscribe
    if request.post?
      teacher = Teacher.find_by(email_updates_unsubscribe_key: params[:unsubscribe_key])

      if teacher
        teacher.update!(email_updates_status: nil)
        redirect_to unsubscribed_email_updates_path
      else
        flash[:error] = "Invalid unsubscribe link"
        redirect_to root_path
      end
    end
  end

  def unsubscribed; end

private

  def unsubscribe_link
    unsubscribe_email_updates_url(unsubscribe_key: current_teacher.email_updates_unsubscribe_key)
  end
end
