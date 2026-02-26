# frozen_string_literal: true

module Admin
  module Applications
    class ChangeTrainingStatusesController < AdminController
      before_action :set_form

      def create
        if @form.invalid?
          render :new, status: :unprocessable_entity and return
        end

        service = Participants::Strategy.for(
          application: @form.application,
          training_status: @form.training_status,
          reason: @form.reason,
        )

        service.call

        if service.errors.any?
          @form.errors.copy!(service.errors)
          render :new, status: :unprocessable_entity
        else
          redirect_to admin_application_path(@form.application)
        end
      end

    private

      def set_form
        @form = Admin::Applications::ChangeTrainingStatusForm.new(
          training_status_params,
        )
      end

      def training_status_params
        params.fetch(:form, {})
          .permit(:training_status, :reason)
          .merge(id: params[:id])
      end
    end
  end
end
