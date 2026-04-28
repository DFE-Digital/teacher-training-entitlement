require Rails.root.join("lib/tasks/api_test/helpers/change_funded_place")

module Admin
  module Applications
    module APITests
      class ChangeFundedPlaceController < ::Admin::ApplicationsController
        def create
          @response = ChangeFundedPlace.new(
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
