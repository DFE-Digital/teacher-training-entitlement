class Admin::Settings::RegistrationClosed::ReopeningEmailSubscriptionsController < AdminController
  before_action :require_super_admin

  def index
    @all_subscriptions = EmailUpdateSubscription.order(:created_at)
    @pagy, @subscriptions = pagy(@all_subscriptions)

    respond_to do |format|
      format.html
      format.csv do
        response.headers["Content-Type"] = "text/csv; charset=utf-8"
        response.headers["Content-Disposition"] = "attachment; filename=reopening_email_subscriptions.csv"
      end
    end
  end

  def unsubscribe
    @subscription = EmailUpdateSubscription.find(params[:id])
    if request.post?
      flash[:success] = "Email '#{@subscription.email}' unsubscribed"
      @subscription.destroy!

      redirect_to admin_settings_registration_closed_reopening_email_subscriptions_path
    end
  end
end
