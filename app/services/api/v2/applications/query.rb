module API
  module V2
    module Applications
      # Provider-visible applications for API V2: every application the provider is or was
      # assigned to, one assignment per application (the current one, else the latest
      # previous one), as in the V1 Applications::Query.
      #
      # Each row carries `effective_updated_at`: the latest change to anything that alters the
      # V2 representation, i.e. the application, its teacher (significant changes only, as in
      # V1), the provider's assignment, the institution, and the provider's own declarations
      # (which are touched when an outcome is recorded). It is computed in the same query, so
      # query counts stay flat, and is used for the updated_at attribute, filter and sort.
      #
      # `sort` is a list of [field, :asc | :desc] pairs over SORT_FIELDS; the application
      # ecf_id is always appended as a unique tie-breaker so cursors are stable.
      class Query
        SORT_FIELDS = %w[created_at updated_at].freeze
        DEFAULT_SORT = [["updated_at", :asc]].freeze

        attr_reader :scope, :effective_updated_at, :sort

        def initialize(lead_provider:, filters: {}, sort: DEFAULT_SORT)
          @effective_updated_at = Arel.sql(effective_updated_at_sql(lead_provider))
          @sort = sort
          @scope = lead_provider
            .application_lead_providers
            .where(id: lead_provider.application_lead_providers.preferred_per_application)
            .joins(application: [:user, { course_cohort: :course }])
            .joins("LEFT OUTER JOIN institutions ON institutions.id = applications.institution_id")
            .select("application_lead_providers.*", "#{effective_updated_at} AS effective_updated_at")
            .preload(
              application: [
                :user,
                { course_cohort: { course: :milestones } },
                { institution: :institutionable },
              ],
            )

          apply_filters(filters)
        end

        def application_lead_providers
          scope.order(Arel.sql(sort_keys.map { |key| "#{key[:sql]} #{key[:direction].upcase}" }.join(", ")))
        end

        # The full sort order for CursorPaginator.
        def sort_keys
          sort.map { |field, direction| sort_key(field, direction) } +
            [{ name: "id", sql: "applications.ecf_id", direction: :asc, type: :uuid }]
        end

        def application_lead_provider(ecf_id:)
          scope.find_by!(applications: { ecf_id: })
        end

      private

        def sort_key(field, direction)
          sql = case field
                when "created_at" then "applications.created_at"
                when "updated_at" then effective_updated_at
                else raise ArgumentError, "unsupported sort field #{field}"
                end

          { name: field, sql:, direction:, type: :time }
        end

        def effective_updated_at_sql(lead_provider)
          declarations_updated_at = Declaration
            .with_lead_provider(lead_provider)
            .where("declarations.application_id = applications.id")
            .select("MAX(declarations.updated_at)")
            .to_sql

          <<~SQL.squish
            GREATEST(
              applications.updated_at,
              users.significantly_updated_at,
              application_lead_providers.updated_at,
              institutions.updated_at,
              (#{declarations_updated_at})
            )
          SQL
        end

        def apply_filters(filters)
          filter_by_course(filters[:course])
          filter_by_term(filters[:term])
          filter_by_academic_year(filters[:academic_year])
          filter_by_funding_eligible(filters[:funding_eligible])
          filter_by_funding_uplift(filters[:funding_uplift])
          filter_by_teacher_trn(filters[:teacher_trn])
          filter_by_teacher_ecf_id(filters[:teacher_ecf_id])
          filter_by_email(filters[:email])
          filter_by_updated_since(filters[:updated_since])
        end

        def filter_by_course(identifiers)
          scope.merge!(Course.where(identifier: identifiers)) if identifiers
        end

        def filter_by_term(terms)
          scope.merge!(CourseCohort.where(term_identifier: terms)) if terms
        end

        def filter_by_academic_year(years)
          scope.merge!(CourseCohort.where(academic_year: years)) if years
        end

        def filter_by_funding_eligible(value)
          return if value.nil?

          eligible = Application.eligible_for_funding
          scope.merge!(value ? eligible : Application.where.not(id: eligible.select(:id)))
        end

        # Funding uplift is not yet sourced and is always null, so it matches neither true nor false.
        def filter_by_funding_uplift(value)
          @scope = scope.none unless value.nil?
        end

        def filter_by_teacher_trn(trns)
          scope.merge!(User.where(trn: trns)) if trns
        end

        def filter_by_teacher_ecf_id(ecf_ids)
          scope.merge!(User.where(ecf_id: ecf_ids)) if ecf_ids
        end

        def filter_by_email(emails)
          scope.merge!(Application.with_email(emails)) if emails
        end

        def filter_by_updated_since(time)
          @scope = scope.where("#{effective_updated_at} >= ?", time) if time
        end
      end
    end
  end
end
