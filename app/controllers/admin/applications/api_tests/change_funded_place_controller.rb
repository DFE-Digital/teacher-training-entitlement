module Admin
  module Applications
    module APITests
      class ChangeFundedPlaceController < APITestsController
        def create
          @response = ::APITests::ChangeFundedPlace.new(
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
