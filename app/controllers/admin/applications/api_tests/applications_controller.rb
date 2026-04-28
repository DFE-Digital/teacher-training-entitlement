require Rails.root.join("lib/tasks/api_test/helpers/show_application")
require Rails.root.join("lib/tasks/api_test/helpers/list_applications")

module Admin
  module Applications
    module APITests
      class ApplicationsController < ::Admin::ApplicationsController
        def show
          @response = ShowApplication.new(application: @application).call
        end

        def index
          @response = ListApplications.new(lead_provider: @application.lead_provider, filters:).call
        end

      private

        def filters
          return {} if params[:form].nil?

          params.require(:form).permit(:status)
        end
      end
    end
  end
end
