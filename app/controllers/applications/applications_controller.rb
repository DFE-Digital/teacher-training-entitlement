module Applications
  class ApplicationsController < LoggedInController
    helper_method :application

    def index
      latest_application = current_user.applications.order(created_at: :desc).first
      redirect_to application_path(latest_application.ecf_id) if latest_application
    end

    def show
      @application = current_user.applications.find_by_ecf_id!(params[:ecf_id])
    end

  protected

    def application
      @application ||= Application.find_by_ecf_id!(params[:application_ecf_id])
    end
  end
end
