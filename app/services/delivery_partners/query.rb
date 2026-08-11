module DeliveryPartners
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider:, cohort_start_years: :ignore, sort: nil)
      @scope = all_delivery_partners
      @sort = sort

      where_lead_provider_is(lead_provider)
      where_cohort_start_year_in(cohort_start_years)
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

    def where_lead_provider_is(lead_provider)
      scope.merge!(DeliveryPartner.where(delivery_partnerships: { lead_provider: lead_provider }))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(DeliveryPartner.where(cohorts: { start_year: extract_conditions(cohort_start_years) }))
    end

    def order_by
      sort_order(sort:, model: DeliveryPartner, default: { name: :asc })
    end

    def all_delivery_partners
      DeliveryPartner.distinct
                     .joins(delivery_partnerships: [{ course_cohort: :cohort }, :lead_provider])
                     .includes(delivery_partnerships: { course_cohort: :cohort })
    end
  end
end
