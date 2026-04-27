require Rails.root.join("lib/tasks/api_test/helpers/completed_declaration")

module Admin
  module Applications
    module APITests
      class CompletedDeclarationsController < ::Admin::ApplicationsController
        def create
          @response = CompletedDeclaration.new(
            application: @application,
            delivery_partner: DeliveryPartner.find(form_params[:delivery_partner_id]),
            has_passed: form_params[:has_passed],
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
