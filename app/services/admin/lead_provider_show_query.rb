module Admin
  class LeadProviderShowQuery
    def initialize(lead_provider:, cohort: nil, academic_year: nil)
      @lead_provider = lead_provider
      @search_scope = if cohort
                        { cohort: }
                      elsif academic_year
                        { academic_year: }
                      end
    end

    attr_reader :details

    def call
      applications = @lead_provider.applications
                       .includes(
                         :current_application_lead_provider,
                         :lead_provider, :user, :course, :cohort,
                         course_cohort: %i[course cohort]
                       )
                       .order(created_at: :desc)

      applications.merge!(Application.where(course_cohorts: @search_scope)) if @search_scope

      delivery_partners = @lead_provider.delivery_partners
                            .joins(delivery_partnerships: :course_cohort)
                            .where(course_cohorts: @search_scope)
                            .distinct

      statements = @lead_provider.statements.order(start_date: :desc)

      if @search_scope&.fetch(:cohort, nil)
        statements.merge!(
          Statement.joins(:course_cohorts).where(course_cohorts: @search_scope),
        )
      end

      if @search_scope&.fetch(:academic_year, nil)
        statements.merge!(
          Statement.where(academic_year: @search_scope[:academic_year]),
        )
      end

      @details = {
        applications:,
        delivery_partners:,
        statements: statements.distinct,
      }
    end
  end
end
