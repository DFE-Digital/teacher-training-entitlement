require Rails.root.join("lib/tasks/api_test/helpers/accept_application")

module Admin
  module Applications
    module APITests
      class AcceptController < APITestsController
        def create
          @response = AcceptApplication.new(
            application: @application,
            funded_place: form_params[:funded_place],
          ).call
        end

      private

        def form_params
          params.require(:form).permit(:funded_place)
        end
      end
    end
  end
end
