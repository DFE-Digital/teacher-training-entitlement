class EmailUpdatesController < PublicPagesController
  before_action only: %i[create] do
    redirect_to root_path unless current_user&.persisted?
  end

  def create
    @subscription = EmailUpdateSubscription.find_or_initialize_by(
      email: current_user.email,
      status: EmailUpdateSubscription::NPD_REGISTRATION_OPEN,
    )
    @subscription.update!(full_name: current_user.full_name)

    GenericMailer.with(
      to: @subscription.email,
      name: @subscription.full_name,
      unsubscribe_link: unsubscribe_email_updates_url(unsubscribe_key: @subscription.unsubscribe_key),
    ).email_updates_confirmation.deliver_later
  end

  def unsubscribe
    if request.post?
      subscription = EmailUpdateSubscription.find_by(unsubscribe_key: params[:unsubscribe_key])

      if subscription
        subscription.destroy!
        redirect_to unsubscribed_email_updates_path
      else
        flash[:error] = "Invalid unsubscribe link"
        redirect_to root_path
      end
    end
  end

  def unsubscribed; end
end
