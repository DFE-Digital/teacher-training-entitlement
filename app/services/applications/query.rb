module Applications
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider:, cohort_start_years: :ignore, updated_since: :ignore, lead_provider_approval_status: :ignore, participant_ids: :ignore, sort: nil)
      @scope = lead_provider.applications.includes(
        :user,
        :institution,
        course_cohort: %i[course cohort schedule],
      )
      @sort = sort

      where_lead_provider_approval_status_in(lead_provider_approval_status)
      where_cohort_start_year_in(cohort_start_years)
      where_updated_since(updated_since)
      where_participant_ids_in(participant_ids)
    end

    def applications
      scope.order(order_by)
    end

    def application(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_lead_provider_approval_status_in(lead_provider_approval_status)
      return if ignore?(filter: lead_provider_approval_status)

      scope.merge!(Application.where(lead_provider_approval_status: extract_conditions(lead_provider_approval_status, allowlist: Application.lead_provider_approval_statuses.values)))
    end

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(Application.where(lead_provider:))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(Application.joins(course_cohort: :cohort).where(cohorts: { start_year: extract_conditions(cohort_start_years) }))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      applications_updated_since = Application.where(updated_at: updated_since..)
      users_updated_since = Application.where(user: { significantly_updated_at: updated_since.. })
      scope.merge!(applications_updated_since.or(users_updated_since))
    end

    def where_participant_ids_in(participant_ids)
      return if ignore?(filter: participant_ids)

      scope.merge!(Application.where(users: { ecf_id: extract_conditions(participant_ids) }))
    end

    def order_by
      sort_order(sort:, model: Application, default: { created_at: :asc })
    end

    def alternative_courses
      Course
        .all
        .each_with_object({}) { |c, h| h[c.id] = c.rebranded_alternative_courses.map(&:id) }
        .to_json
    end
  end
end
