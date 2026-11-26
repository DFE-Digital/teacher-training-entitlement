module API
  module V2
    class ErrorsController < BaseController
      def not_found
        render_endpoint_not_found
      end
    end
  end
end
