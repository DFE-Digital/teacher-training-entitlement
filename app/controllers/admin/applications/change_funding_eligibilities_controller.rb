# frozen_string_literal: true

module Admin
  module Applications
    class ChangeFundingEligibilitiesController < ApplicationsController
      before_action :set_form

      def create
        if @form.invalid?
          render :new, status: :unprocessable_content and return
        end

        service = ::Applications::ChangeFundingEligibility.new(
          application:,
          eligible_for_funding: @form.eligible_for_funding,
        )

        service.call

        if service.errors.any?
          @form.errors.copy!(service.errors)
          render :new, status: :unprocessable_content
        else
          flash[:success] =
            "Funding eligibility has been changed to ‘#{application.eligible_for_funding ? 'Yes' : 'No'}’"

          redirect_to admin_application_path(application)
        end
      end

    private

      def set_form
        @form = Admin::Applications::ChangeFundingEligibilityForm.new(
          form_params,
        )
      end

      def form_params
        params
          .fetch(:form, { eligible_for_funding: application.eligible_for_funding })
          .permit(:eligible_for_funding)
          .merge(application:)
      end
    end
  end
end
