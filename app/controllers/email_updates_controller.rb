class EmailUpdatesController < PublicPagesController
  before_action only: %i[create] do
    redirect_to root_path unless current_user&.persisted?
  end

  def create
    current_user.update!(email_updates_status: User::EMAIL_NPD_REGISTRATION_OPEN)

    GenericMailer.with(
      to: current_user.email,
      name: current_user.full_name,
      unsubscribe_link:,
    ).email_updates_confirmation.deliver_later
  end

  def unsubscribe
    if request.post?
      user = User.find_by(email_updates_unsubscribe_key: params[:unsubscribe_key])

      if user
        user.update!(email_updates_status: nil)
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
    "#{Rails.configuration.service_base_url}#{unsubscribe_email_updates_path(unsubscribe_key: current_user.email_updates_unsubscribe_key)}"
  end
end
