module Applications
  class ApplicationsController < LoggedInController
    helper_method :application

    def index
      @applications = current_user.applications
      redirect_to application_path(@applications.first.ecf_id) if @applications.one?

      @active_applications = @applications.active_applications.order(created_at: :desc, id: :desc)
      @expired_applications = @applications.expired_applications.order(created_at: :desc, id: :desc)
    end

    def show
      @application = current_user.applications.find_by_ecf_id(params[:ecf_id])
      redirect_to applications_path if @application.nil?
    end

  protected

    def application
      @application ||= Application.find_by_ecf_id!(params[:application_ecf_id])
    end
  end
end
