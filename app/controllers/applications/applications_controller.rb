module Applications
  class ApplicationsController < LoggedInController
    helper_method :application

  protected

    def application
      @application ||= Application.find_by_ecf_id!(params[:application_ecf_id])
    end
  end
end
