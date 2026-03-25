# frozen_string_literal: true

module Admin
  module Applications
    class ChangeCohortController < ApplicationsController
      before_action :set_form

      def create
        if @form.invalid?
          render :show, status: :unprocessable_entity and return
        end

        service = ::Applications::ChangeCohort.new(
          application:,
          new_cohort: @form.course_cohort.cohort,
          override_declarations_check: @form.override_declarations_check,
        )

        service.call

        if service.errors.any?
          @form.errors.copy!(service.errors)
          render :show, status: :unprocessable_entity
        else
          redirect_to admin_application_path(application)
        end
      end

    private

      def set_form
        @form = Admin::Applications::ChangeCohortForm.new(
          form_params,
        )
      end

      def form_params
        params
          .fetch(:form, {})
          .permit(:course_cohort_id)
          .merge(application:)
      end
    end
  end
end
