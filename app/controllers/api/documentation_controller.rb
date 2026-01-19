require "api/version"

module API
  class DocumentationController < PublicPagesController
    layout "api_docs"
    before_action :set_api_version

  private

    def set_api_version
      @version = params[:version]

      raise ActionController::RoutingError, "Not found" unless API::Version.exists?(@version)
    end
  end
end
