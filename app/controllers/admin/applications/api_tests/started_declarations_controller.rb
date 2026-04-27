require Rails.root.join("lib/tasks/api_test/helpers/started_declaration")

module Admin
  module Applications
    module APITests
      class StartedDeclarationsController < ::Admin::ApplicationsController
        def create
          @response = StartedDeclaration.new(
            application: @application,
            delivery_partner: DeliveryPartner.find(form_params[:delivery_partner_id]),
          ).call
        end

      private

        def form_params
          params.require(:form).permit(:delivery_partner_id)
        end
      end
    end
  end
end
