module Applications
  class ApplicationsController < LoggedInController
    before_action :application
    helper_method :application

    def index
      most_recent_application = current_user.applications.order(created_at: :desc).first

      if most_recent_application
        redirect_to application_path(most_recent_application.ecf_id)
      else
        redirect_to root_path
      end
    end

    def show
      redirect_to applications_path if application.nil?
    end

  protected

    def application
      return nil if application_ecf_id.nil?

      @application ||= current_user.applications.find_by_ecf_id(application_ecf_id)
    end

    def application_ecf_id
      @application_ecf_id ||= params[:application_ecf_id] || params[:ecf_id]
    end
  end
end
