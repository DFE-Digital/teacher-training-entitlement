module Admin
  module Applications
    module APITests
      class WithdrawController < APITestsController
        def create
          @response = ::APITests::WithdrawApplication.new(application: @application).call
        end
      end
    end
  end
end
