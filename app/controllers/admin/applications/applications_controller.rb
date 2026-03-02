module Admin
  module Applications
    class ApplicationsController < AdminController
    protected

      def application
        @application ||= Application.find(params[:id])
      end
    end
  end
end
