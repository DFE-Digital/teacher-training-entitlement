# frozen_string_literal: true

module Admin
  module Applications
    class ChangeCohortController < AdminController
      before_action :set_form
      delegate :application, :cohort, to: :@form

      def create
        if @form.invalid?
          render :show, status: :unprocessable_entity and return
        end

        service = Applications::ChangeCohort.new(
          application: @form.application,
          new_cohort: @form.cohort,
          override_declarations_check: @form.override_declarations_check,
        )

        service.call

        if service.errors.any?
          @form.errors.copy!(service.errors)
          render :show, status: :unprocessable_entity
        else
          redirect_to admin_application_path(@form.application)
        end
      end

    private

      def set_form
        @form = Admin::Applications::ChangeCohortForm.new(
          cohort_params,
        )
      end

      def cohort_params
        params
          .fetch(:form, {})
          .permit(:cohort_id)
          .merge(id: params[:id])
      end
    end
  end
end
