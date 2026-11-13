module API
  module V2
    class ErrorsController < BaseController
      def not_found
        render_errors(
          status: :not_found,
          title: "The requested endpoint does not exist",
          details: "#{request.method} #{request.path}",
        )
      end
    end
  end
end
