module Applications
  module ChangeProvider
    class ProvidersController < ::Applications::ApplicationsController
      include MultiStepFormSession

      before_action :set_form
      storing_form_session_as :change_provider

      def index; end

      def create
        render :index, status: :unprocessable_content and return unless @form.valid?

        store_session_form_data!(@form.attributes)

        redirect_to application_change_provider_check_answers_path(application.ecf_id)
      end

      helper_method :providers

    private

      def providers
        @providers ||= LeadProvider
          .for(course: application.course)
          .alphabetical
          .reject { |p| p.id == application.lead_provider_id }
      end

      def set_form
        @form = Applications::ChangeProvider::ProvidersForm.new(form_params)
      end

      def form_params
        params.fetch(:form, {})
              .permit(:provider_id)
              .merge(application:)
      end
    end
  end
end
