module Applications
  module ChangeProvider
    class ChangeProviderController < ::Applications::ApplicationsController
      before_action :ensure_can_change_provider

    private

      def ensure_can_change_provider
        redirect_to applications_path and return unless application

        redirect_to application_path(application.ecf_id) unless application.can_change_provider?
      end
    end
  end
end
