module Admin
  class LeadProvidersQuery
    def initialize(cohort: nil, academic_year: nil)
      @search_scope = if cohort
                        { cohort: }
                      elsif academic_year
                        { academic_year: }
                      end
    end

    attr_reader :resources

    def call
      scope = LeadProvider
                .includes(:applications, :course_cohorts, applications: :course_cohort)
                .order(name: :asc)

      scope.merge!(LeadProvider.where(course_cohorts: @search_scope)) if @search_scope

      @resources = scope.map do |resource|
        applications = resource.applications.select do |application|
          next true if @search_scope[:cohort] && application.course_cohort.cohort_id == @search_scope[:cohort].id
          next true if @search_scope[:cohort] && application.course_cohort.academic_year == @search_scope[:academic_year]

          true
        end
        [resource, applications.size]
      end
    end
  end
end
