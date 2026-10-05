module Admin
  module Applications
    class RevertToPendingController < AdminController
      before_action :set_form

      def create
        if @form.invalid?
          render :new, status: :unprocessable_content and return
        end

        service = ::Applications::RevertToPending.new(
          application: @form.application,
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
        @form = Admin::Applications::RevertToPendingForm.new(form_params)
      end

      def form_params
        params.fetch(:form, {})
          .permit(:change_status_to_pending)
          .merge(application: Application.find_by_ecf_id!(params[:id]))
      end
    end
  end
end
