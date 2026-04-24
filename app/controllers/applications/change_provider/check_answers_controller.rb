module Applications
  module ChangeProvider
    class CheckAnswersController < ::Applications::ApplicationsController
      include MultiStepFormSession

      storing_form_session_as :change_provider

      def index
        redirect_to application_path(application.ecf_id) and return unless application.can_change_provider?

        redirect_to application_change_provider_start_index_path(application.ecf_id) and return if new_provider.nil?
      end

      def create
        redirect_to application_change_provider_start_index_path(application.ecf_id) and return if new_provider.nil?

        service = Applications::ChangeLeadProvider.new(application:, new_provider:)

        service.call

        if service.errors.any?
          flash[:alert] = {
            title: t("applications.change_provider.check_answers.fail.title"),
            message: service.errors.full_messages.join("; "),
          }

          redirect_to application_change_provider_check_answers_path(application.ecf_id) and return
        end

        flash[:success] = {
          title: t("applications.change_provider.check_answers.success.title"),
          message: t("applications.change_provider.check_answers.success.message"),
        }

        clear_session_form_data!

        redirect_to application_path(application.ecf_id)
      end

      helper_method :new_provider

    private

      def new_provider
        return nil if new_provider_id.blank?

        @new_provider ||= LeadProvider.find(new_provider_id)
      end

      def new_provider_id
        session_form_data[:provider_id]
      end
    end
  end
end
