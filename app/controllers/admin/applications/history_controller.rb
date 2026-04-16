# frozen_string_literal: true

module Admin
  module Applications
    class HistoryController < AdminController
      before_action :set_application

    private

      def set_application
        @application = Application.eager_load(:application_events).find(params[:id])
      end
    end
  end
end
