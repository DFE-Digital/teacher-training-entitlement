module CourseCohorts
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider:, academic_years: :ignore, course_identifier: :ignore, sort: nil)
      @scope = lead_provider
                 .course_cohorts
                 .includes(:course, :cohort)

      @sort = sort

      where_academic_year_in(academic_years)
      where_course_identifier_in(course_identifier)
    end

    def course_cohorts
      scope.order(order_by)
    end

  private

    def where_academic_year_in(academic_years)
      return if ignore?(filter: academic_years)

      scope.merge!(CourseCohort.where(academic_year: extract_conditions(academic_years)))
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
