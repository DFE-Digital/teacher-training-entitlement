require Rails.root.join("lib/tasks/api_test/helpers/withdraw_application")

module Admin
  module Applications
    module APITests
      class WithdrawController < ::Admin::ApplicationsController
        def create
          @response = WithdrawApplication.new(application: @application).call
        end
      end
    end
  end
end
