module Admin
  module Applications
    class ApplicationsController < AdminController
    protected

      def application
        @application ||= Application.find_by!(ecf_id: params[:id])
      end
    end
  end
end
