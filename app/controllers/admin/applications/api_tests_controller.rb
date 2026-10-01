# frozen_string_literal: true

module Admin
  module Applications
    class APITestsController < ::Admin::ApplicationsController
      before_action :require_super_admin
      before_action :set_application

      def index; end
    end
  end
end
