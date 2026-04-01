# frozen_string_literal: true

module Admin
  module Applications
    class ChangeStatusesController < AdminController
      before_action :set_form

      def create
        if @form.invalid?
          render :new, status: :unprocessable_content and return
        end

        service = ::Applications::Strategy.for(
          application: @form.application,
          status: @form.status,
          reason: @form.reason,
          admin_user: current_admin,
        )

        service.call

        if service.errors.any?
          @form.errors.copy!(service.errors)
          render :new, status: :unprocessable_content
        else
          redirect_to admin_application_path(@form.application)
        end
      end

    private

      def set_form
        @form = Admin::Applications::ChangeStatusForm.new(
          status_params,
        )
      end

      def status_params
        params.fetch(:form, {})
          .permit(:status, :reason)
          .merge(id: params[:id])
      end
    end
  end
end
