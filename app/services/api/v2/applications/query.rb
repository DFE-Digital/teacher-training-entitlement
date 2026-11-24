module API
  module V2
    module Applications
      # Provider-visible applications for API V2: every application the provider is or was
      # assigned to, one assignment per application (the current one, else the latest
      # previous one), as in the V1 Applications::Query.
      #
      # Each row carries `effective_updated_at`, used for the updated_at attribute, the
      # updated_since filter and the updated_at sort. It is the latest change to the attributes
      # rendered on the V2 application resource and to the teacher:
      # - the application itself (applications.updated_at);
      # - the requesting provider's assignment (status `reassigned`, contract_assigned_at and
      #   contract_unassigned_at);
      # - the nested institution;
      # - the teacher's significant changes (users.significantly_updated_at, as in V1).
      # Declarations and outcomes are deliberately left out: payment runs, clawbacks and voids
      # must not mark applications as updated. When surveys exist (api-v2/009), their
      # updated_at must be added to EFFECTIVE_UPDATED_AT_SQL.
      #
      # The expression is computed once, in an inner subquery aliased as the
      # application_lead_providers table; ordering, the updated_since filter and cursor
      # keysets refer to its output columns, so query counts stay flat.
      #
      # `sort` is a list of [field, :asc | :desc] pairs over SORT_FIELDS; the application
      # ecf_id is always appended as a unique tie-breaker so cursors are stable.
      class Query
        SORT_FIELDS = %w[created_at updated_at].freeze
        DEFAULT_SORT = [["updated_at", :asc]].freeze
        EFFECTIVE_UPDATED_AT_SQL = <<~SQL.squish.freeze
          GREATEST(
            applications.updated_at,
            users.significantly_updated_at,
            application_lead_providers.updated_at,
            institutions.updated_at
          )
        SQL
        SORT_COLUMNS = {
          "created_at" => "application_lead_providers.application_created_at",
          "updated_at" => "application_lead_providers.effective_updated_at",
        }.freeze
        ID_COLUMN = "application_lead_providers.application_ecf_id".freeze

        attr_reader :sort

        def initialize(lead_provider:, filters: {}, sort: DEFAULT_SORT)
          @sort = sort
          @updated_since = filters[:updated_since]
          @rows = lead_provider
            .application_lead_providers
            .where(id: lead_provider.application_lead_providers.preferred_per_application)
            .joins(application: [:user, { course_cohort: :course }])
            .joins("LEFT OUTER JOIN institutions ON institutions.id = applications.institution_id")
            .select(
              "application_lead_providers.*",
              "applications.created_at AS application_created_at",
              "applications.ecf_id AS application_ecf_id",
              "#{EFFECTIVE_UPDATED_AT_SQL} AS effective_updated_at",
            )

          apply_filters(filters)
        end

        # Visible assignments with their effective_updated_at, filtered and unordered.
        def scope
          @scope ||= wrap(rows)
        end

        def application_lead_providers
          scope.order(Arel.sql(sort_keys.map { |key| "#{key[:sql]} #{key[:direction].upcase}" }.join(", ")))
        end

        # The full sort order for CursorPaginator.
        def sort_keys
          sort.map { |field, direction| sort_key(field, direction) } +
            [{ name: "id", sql: ID_COLUMN, direction: :asc, type: :uuid }]
        end

        def application_lead_provider(ecf_id:)
          wrap(rows.where(applications: { ecf_id: })).take!
        end

      private

        attr_reader :rows, :updated_since

        # Selects from the inner query as if it were the application_lead_providers table, so
        # its computed columns can be referenced by name.
        def wrap(inner)
          relation = ApplicationLeadProvider
            .from(inner, :application_lead_providers)
            .select("application_lead_providers.*")
            .preload(
              application: [
                :user,
                { course_cohort: { course: :milestones } },
                { institution: :institutionable },
              ],
            )
          updated_since ? relation.where("#{SORT_COLUMNS['updated_at']} >= ?", updated_since) : relation
        end

        def sort_key(field, direction)
          sql = SORT_COLUMNS.fetch(field) { raise ArgumentError, "unsupported sort field #{field}" }

          { name: field, sql:, direction:, type: :time }
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
        end

        def filter_by_course(identifiers)
          rows.merge!(Course.where(identifier: identifiers)) if identifiers
        end

        def filter_by_term(terms)
          rows.merge!(CourseCohort.where(term_identifier: terms)) if terms
        end

        def filter_by_academic_year(years)
          rows.merge!(CourseCohort.where(academic_year: years)) if years
        end

        def filter_by_funding_eligible(value)
          return if value.nil?

          eligible = Application.eligible_for_funding
          rows.merge!(value ? eligible : Application.where.not(id: eligible.select(:id)))
        end

        # Funding uplift is not yet sourced and is always null, so it matches neither true nor false.
        def filter_by_funding_uplift(value)
          @rows = rows.none unless value.nil?
        end

        def filter_by_teacher_trn(trns)
          rows.merge!(User.where(trn: trns)) if trns
        end

        def filter_by_teacher_ecf_id(ecf_ids)
          rows.merge!(User.where(ecf_id: ecf_ids)) if ecf_ids
        end

        def filter_by_email(emails)
          rows.merge!(Application.with_email(emails)) if emails
        end
      end
    end
  end
end
