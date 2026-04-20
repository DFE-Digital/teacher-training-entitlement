module Applications
  module ChangeProvider
    class CheckAnswersController < ::Applications::ApplicationsController
      include MultiStepFormSession

      storing_form_session_as :change_provider

      def index
        redirect_to application_change_provider_start_index_path(application.ecf_id) and return if new_provider.nil?
      end

      def create
        redirect_to application_change_provider_start_index_path(application.ecf_id) and return if new_provider.nil?

        # TODO: - Create new application with new provider and retire old application
        # Don't leave this in :)
        application.update!(lead_provider_id: new_provider.id)

        GenericMailer.with(
          to: application.user.email,
          full_name: application.user.full_name,
          provider_name: application.lead_provider.name,
          course_name: application.course.name,
          cohort_date: application.cohort.name,
          ecf_id: application.ecf_id,
          sign_in_link: Rails.configuration.sign_in_link,
          feedback_link: Rails.configuration.feedback_link,
        ).change_provider.deliver_later

        flash[:notice] = {
          title: t("applications.change_provider.check_answers.success.title"),
          message: t("applications.change_provider.check_answers.success.message"),
        }

        redirect_to application_path(application.ecf_id)

        clear_session_form_data!
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
