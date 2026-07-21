module Admin
  module Applications
    class RejectionController < ApplicationsController
      before_action :set_application

      def edit; end

      def update
        if @application.pending_status?
          service = ::Applications::Reject.new(
            application: @application,
            reason: "rejected-by-admin-user",
          )
          service.call
          if service.errors.blank?
            redirect_to admin_application_path(@application)
          else
            render :edit, status: :unprocessable_content
          end
        else
          render :edit, status: :unprocessable_content
        end
      end

    private

      def set_application
        @application = Application.find(params[:id])
      end
    end
  end
end
