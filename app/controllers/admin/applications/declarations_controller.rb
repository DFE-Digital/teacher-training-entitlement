module Admin
  module Applications
    class DeclarationsController < AdminController
      def index
        @application = Application.find(params[:id])

        @declarations = @application.declarations
                          .includes(:lead_provider,
                                    :participant_outcomes,
                                    :statements,
                                    :delivery_partner,
                                    :secondary_delivery_partner,
                                    :versions,
                                    milestone: { course_cohort: :cohort })
                          .order(created_at: :asc, id: :asc)
      end
    end
  end
end
