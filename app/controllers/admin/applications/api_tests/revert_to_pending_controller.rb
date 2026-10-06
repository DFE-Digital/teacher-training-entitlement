module Admin
  module Applications
    module APITests
      class RevertToPendingController < APITestsController
        def create
          @response = ::APITests::RevertToPendingApplication.new(application: @application).call
        end
      end
    end
  end
end
