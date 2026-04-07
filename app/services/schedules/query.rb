module Schedules
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider:, cohort_start_years: :ignore, course_identifier: :ignore, sort: nil)
      @scope = lead_provider
                 .course_cohorts
                 .includes(:schedule, :course, :cohort)

      @sort = sort

      where_cohort_start_year_in(cohort_start_years)
      where_course_identifier_in(course_identifier)
    end

    def course_cohorts
      scope.order(order_by)
    end

  private

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(CourseCohort.where(cohorts: { start_year: extract_conditions(cohort_start_years) }))
    end

    def where_course_identifier_in(course_identifier)
      return if ignore?(filter: course_identifier)

      scope.merge!(CourseCohort.where(courses: { identifier: extract_conditions(course_identifier) }))
    end

    def order_by
      sort_order(sort:, model: CourseCohort, default: { created_at: :asc })
    end
  end
end
