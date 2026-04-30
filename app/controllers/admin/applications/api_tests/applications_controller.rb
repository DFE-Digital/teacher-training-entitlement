module Admin
  module Applications
    module APITests
      class ApplicationsController < APITestsController
        def show
          @response = ::APITests::ShowApplication.new(application: @application).call
        end

        def index
          @response = ::APITests::ListApplications.new(lead_provider: @application.lead_provider, filters:).call
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
