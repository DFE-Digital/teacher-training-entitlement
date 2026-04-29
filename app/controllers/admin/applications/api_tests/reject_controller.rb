require Rails.root.join("lib/tasks/api_test/helpers/reject_application")

module Admin
  module Applications
    module APITests
      class RejectController < APITestsController
        def create
          @response = RejectApplication.new(application: @application).call
        end
      end
    end
  end
end
