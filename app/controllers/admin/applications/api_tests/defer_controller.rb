require Rails.root.join("lib/tasks/api_test/helpers/defer_application")

module Admin
  module Applications
    module APITests
      class DeferController < ::Admin::ApplicationsController
        def create
          @response = DeferApplication.new(application: @application).call
        end
      end
    end
  end
end
