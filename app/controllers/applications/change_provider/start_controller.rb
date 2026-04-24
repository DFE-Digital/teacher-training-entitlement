module Applications
  module ChangeProvider
    class StartController < ::Applications::ApplicationsController
      include MultiStepFormSession

      before_action :set_form
      storing_form_session_as :change_provider

      def index
        redirect_to application_path(application.ecf_id) unless application.can_change_provider?
      end

      def create
        render :index, status: :unprocessable_content and return unless @form.valid?

        store_session_form_data!(@form.attributes)

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
        params.fetch(:form, { confirmation: session_form_data[:confirmation] })
          .permit(:confirmation).merge(application:)
      end
    end
  end
end
