module Admin
  class LeadProvidersController < AdminController
    include Cohortable

    def index
      @lead_providers = LeadProvider.all
    end

    def show
      @lead_provider = LeadProvider.find(params[:id])

      # Added extra includes :course, :cohort to stop bogus warning issues;
      applications_scope = @lead_provider.applications
                             .includes(:user, :course, :cohort, course_cohort: %i[course cohort])
                             .where(course_cohorts: { cohort: @current_cohort })
                             .order(created_at: :desc)

      @pagy_applications, @applications = pagy(applications_scope, items: 25)

      @pagy_delivery_partners, @delivery_partners = pagy(@lead_provider.delivery_partners_for_cohort(@current_cohort))

      @pagy_statements, @statements = pagy(@lead_provider.statements.where(cohort: @current_cohort))
    end
  end
end
