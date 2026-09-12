module Admin
  module Applications
    class DeclarationsController < AdminController
      def index
        @application = Application.find(params[:id])

        @declarations = @application.declarations
                          .includes(:lead_provider,
                                    :participant_outcomes,
                                    :delivery_partner,
                                    :secondary_delivery_partner,
                                    :statement,
                                    :versions,
                                    milestone: :course)
                          .order(created_at: :asc, id: :asc)
      end
    end
  end
end
