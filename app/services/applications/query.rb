module Applications
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider:, cohort_start_years: :ignore, updated_since: :ignore, participant_ids: :ignore, status: :ignore, course_identifier: :ignore, sort: nil)
      @scope = lead_provider
                 .application_lead_providers
                 .joins(:application)
                 .includes(
                   application: [:user,
                                 :course,
                                 :cohort,
                                 :schedule,
                                 :institution,
                                 { course_cohort: %i[course cohort schedule] }],
                 )
                 .preload(application: { institution: :institutionable })
      @sort = sort

      where_cohort_start_year_in(cohort_start_years)
      where_updated_since(updated_since)
      where_participant_ids_in(participant_ids)
      where_status_in(status)
      where_course_identifier_in(course_identifier)
    end

    def applications
      #      binding.pry
      application_lead_providers.map(&:application)
    end

    def application_lead_providers
      scope.order(order_by)
    end

    def application(id: nil, ecf_id: nil)
      return scope.find_by!(application: { ecf_id: })&.application if ecf_id.present?
      return scope.find_by!(application: { id: })&.application if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(Application.joins(course_cohort: :cohort).where(cohorts: { start_year: extract_conditions(cohort_start_years) }))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      applications_updated_since = Application.where(updated_at: updated_since..)
      users_updated_since = Application.where(users: { significantly_updated_at: updated_since.. })
      scope.merge!(applications_updated_since.or(users_updated_since))
    end

    def where_participant_ids_in(participant_ids)
      return if ignore?(filter: participant_ids)

      scope.merge!(Application.where(users: { ecf_id: extract_conditions(participant_ids) }))
    end

    def where_status_in(status)
      return if ignore?(filter: status)

      if status == Application::REASSIGNED
        scope.merge!(scope.where(current: false))
      elsif status.is_a?(Array) && Application::REASSIGNED.in?(status)
        filtered_status = extract_conditions(status, allowlist: Application::STATUSES) - [Application::REASSIGNED]

        scope.merge!(
          scope.where(current: false)
            .or(Application.where(status: filtered_status)),
        )
      else
        scope.merge!(Application.where(status: extract_conditions(status, allowlist: Application::STATUSES)))
      end
    end

    def where_course_identifier_in(course_identifier)
      return if ignore?(filter: course_identifier)

      scope.merge!(Application.joins(course_cohort: :course).where(courses: { identifier: extract_conditions(course_identifier) }))
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
