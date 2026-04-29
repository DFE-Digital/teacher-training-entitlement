require Rails.root.join("lib/tasks/api_test/helpers/void_declaration")

module Admin
  module Applications
    module APITests
      class VoidDeclarationsController < APITestsController
        before_action :set_declarations

        def create
          @response = VoidDeclaration.new(
            declaration:,
          ).call
        end

      private

        def set_declarations
          @declarations = @application.declarations
        end

        def declaration
          Declaration.find(form_params[:declaration_id])
        end

        def form_params
          params.require(:form).permit(:declaration_id)
        end
      end
    end
  end
end
