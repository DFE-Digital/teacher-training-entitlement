class Admin::Settings::RegistrationClosed::ReopeningEmailSubscriptionsController < AdminController
  before_action :require_super_admin

  def index
    @all_teachers = Teacher.where.not(email_updates_status: nil)
    @pagy, @teachers = pagy(@all_teachers)

    respond_to do |format|
      format.html
      format.csv do
        response.headers["Content-Type"] = "text/csv; charset=utf-8"
        response.headers["Content-Disposition"] = "attachment; filename=reopening_email_subscriptions.csv"
      end
    end
  end

  def unsubscribe
    @teacher = Teacher.find(params[:id])
    if request.post?
      flash[:success] = "Email '#{@teacher.email}' unsubscribed"
      @teacher.update!(email_updates_status: nil)

      redirect_to admin_settings_registration_closed_reopening_email_subscriptions_path
    end
  end
end
