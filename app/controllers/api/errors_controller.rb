module API
  class ErrorsController < BaseController
    def not_found
      render json: {
               error: {
                 title: "The requested endpoint does not exist",
                 detail: "#{request.method} #{request.path}",
               },
             },
             status: :not_found
    end
  end
end
