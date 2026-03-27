module Applications
  class ApplicationsController < LoggedInController
    helper_method :application

    def index
      return unless current_user.applications.count == 1

      redirect_to application_path(current_user.applications.first.ecf_id)
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
