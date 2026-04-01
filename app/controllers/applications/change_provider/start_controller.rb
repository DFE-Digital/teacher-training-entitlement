module Applications
  module ChangeProvider
    class StartController < ::Applications::ApplicationsController
      before_action :set_form

      def index; end

      def create
        render :index, status: :unprocessable_content and return unless @form.valid?

        if @form.confirmation
          redirect_to application_change_provider_providers_path(application.ecf_id)
        else
          redirect_to application_path(application.ecf_id)
        end
      end

    private

      def set_form
        @form = Applications::ChangeProvider::StartForm.new(form_params)
      end

      def form_params
        params.fetch(:form, {}).permit(:confirmation).merge(application:)
      end
    end
  end
end
