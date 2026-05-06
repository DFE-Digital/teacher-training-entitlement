module Admin
  module Applications
    module APITests
      class DeferController < APITestsController
        def create
          @response = ::APITests::DeferApplication.new(application: @application).call
        end
      end
    end
  end
end
