module DeliveryPartners
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider:, cohort_start_years: :ignore, course_identifier: :ignore, sort: nil)
      @scope = all_delivery_partners
      @sort = sort
      @lead_provider = lead_provider

      where_lead_provider_is(lead_provider)
      where_cohort_start_year_in(cohort_start_years)
      where_course_identifier_in(course_identifier)
    end

    def delivery_partners
      scope.order(order_by)
    end

    def delivery_partner(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    attr_reader :lead_provider

    def where_lead_provider_is(lead_provider)
      scope.merge!(DeliveryPartner.where(delivery_partnerships: { lead_provider: lead_provider }))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(
        DeliveryPartner
          .joins(delivery_partnerships: { course: { course_cohorts: :course_cohort_providers } })
          .where(
            courses: {
              course_cohorts: {
                academic_year: extract_conditions(cohort_start_years),
                course_cohort_providers: { lead_provider_id: lead_provider.id },
              },
            },
          ),
      )
    end

    def where_course_identifier_in(course_identifier)
      return if ignore?(filter: course_identifier)

      scope.merge!(DeliveryPartner.where(courses: { identifier: extract_conditions(course_identifier) }))
    end

    def order_by
      sort_order(sort:, model: DeliveryPartner, default: { name: :asc })
    end

    def all_delivery_partners
      DeliveryPartner.distinct
                     .joins(delivery_partnerships: [{ course: { course_cohorts: :cohort } }, :lead_provider])
                     .includes(delivery_partnerships: { course: { course_cohorts: :cohort } })
    end
  end
end
