module Admin
  module Applications
    module APITests
      class RejectController < APITestsController
        def create
          @response = ::APITests::RejectApplication.new(application: @application).call
        end
      end
    end
  end
end
