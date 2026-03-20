module Declarations
  class Query
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider: :ignore, updated_since: :ignore, participant_ids: :ignore, cohort_start_years: :ignore, application_id: :ignore, declaration_type: :ignore, course_identifier: :ignore, include_transferred_applications: false)
      @scope = all_declarations
      @sort = sort

      where_lead_provider_is(lead_provider, include_transferred_applications)
      where_updated_since(updated_since)
      where_participant_ids_in(participant_ids)
      where_cohort_start_year_in(cohort_start_years)
      where_application_id_is(application_id)
      where_declaration_type_in(declaration_type)
      where_course_identifier_in(course_identifier)
    end

    def declarations
      scope.order(created_at: :asc, id: :asc)
    end

    def declaration(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_lead_provider_is(lead_provider, include_transferred_applications)
      return if ignore?(filter: lead_provider)

      relation = Declaration.joins(:application)
      lead_provider_scope = relation.where(lead_provider:)

      if include_transferred_applications
        lead_provider_scope = lead_provider_scope.or(relation.where(application: { lead_provider: }))
      end

      scope.merge!(lead_provider_scope)
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      declarations_updated_since = Declaration.where(updated_at: updated_since..)
      scope.merge!(declarations_updated_since)
    end

    def where_participant_ids_in(participant_ids)
      return if ignore?(filter: participant_ids)

      scope.merge!(Declaration.where(user: { ecf_id: extract_conditions(participant_ids, uuids: true) }))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(Declaration.where(cohort: { start_year: extract_conditions(cohort_start_years) }))
    end

    def where_application_id_is(application_id)
      return if ignore?(filter: application_id)

      scope.merge!(Declaration.joins(:application).where(applications: { ecf_id: application_id }))
    end

    def where_declaration_type_in(declaration_type)
      return if ignore?(filter: declaration_type)

      scope.merge!(Declaration.where(declaration_type: extract_conditions(declaration_type)))
    end

    def where_course_identifier_in(course_identifier)
      return if ignore?(filter: course_identifier)

      scope.merge!(Declaration.joins(application: { course_cohort: :course }).where(courses: { identifier: extract_conditions(course_identifier) }))
    end

    def all_declarations
      Declaration
        .distinct
        .includes(
          :cohort,
          :lead_provider,
          :participant_outcomes,
          application: %i[
            user
            course
            lead_provider
          ],
          statement_items: %i[
            statement
          ],
        )
    end
  end
end
