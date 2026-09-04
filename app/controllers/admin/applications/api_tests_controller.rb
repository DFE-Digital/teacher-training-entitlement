# frozen_string_literal: true

module Admin
  module Applications
    class APITestsController < ::Admin::ApplicationsController
      before_action :require_super_admin

      def index; end

    private

      def redirect_to_current_academic_year; end
    end
  end
end
