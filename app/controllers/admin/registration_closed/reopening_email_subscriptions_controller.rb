class Admin::RegistrationClosed::ReopeningEmailSubscriptionsController < AdminController
  before_action :require_super_admin

  def index
    @all_users = User.where.not(email_updates_status: nil)
    @pagy, @users = pagy(@all_users)

    respond_to do |format|
      format.html
      format.csv do
        response.headers["Content-Type"] = "text/csv; charset=utf-8"
        response.headers["Content-Disposition"] = "attachment; filename=reopening_email_subscriptions.csv"
      end
    end
  end

  def unsubscribe
    @user = User.find(params[:id])
    if request.post?
      flash[:success] = "Email '#{@user.email}' unsubscribed"
      @user.update!(email_updates_status: nil)

      redirect_to admin_registration_closed_reopening_email_subscriptions_path
    end
  end
end
