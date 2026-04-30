module Admin
  class LeadProvidersController < AdminController
    include Cohortable

    def index
      @resources = resources
    end

    def show
      @lead_provider = LeadProvider.find(params[:id])

      # Added extra includes :course, :cohort to stop bogus warning issues;
      applications_scope = @lead_provider.applications
                             .includes(:current_application_lead_provider,
                                       :lead_provider, :user, :course, :cohort,
                                       course_cohort: %i[course cohort])
                             .order(created_at: :desc)

      if @current_cohort
        applications_scope.merge!(Application.where(course_cohorts: { cohort: @current_cohort }))
        @pagy_applications, @applications = pagy(applications_scope, items: 25)

        @pagy_delivery_partners, @delivery_partners = pagy(@lead_provider.delivery_partners_for_cohort(@current_cohort))

        @pagy_statements, @statements = pagy(@lead_provider.statements.where(cohort: @current_cohort))
      else
        @pagy_applications, @applications = pagy(applications_scope, items: 25)
        @pagy_delivery_partners, @delivery_partners = pagy(@lead_provider.delivery_partners.distinct)
        @pagy_statements, @statements = pagy(@lead_provider.statements)
      end
    end

  private

    def resources
      if @current_cohort
        scope = LeadProvider
                  .includes(:applications, :course_cohorts, applications: :course_cohort)
                  .order(name: :asc)
                  .where(course_cohorts: { cohort: @current_cohort })

        # group in memory, no N+1
        @apps_by_provider = scope.each_with_object({}) do |lp, hash|
          hash[lp.id] = lp.applications.select { |a| a.course_cohort.cohort_id == @current_cohort.id }
        end

        scope
      else
        LeadProvider.includes(:applications).all.order(name: :asc)
      end
    end
  end
end
