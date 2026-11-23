module API
  module V2
    module Applications
      # Provider-visible applications for API V2: every application the provider is or was
      # assigned to, one assignment per application (the current one, else the latest
      # previous one), as in the V1 Applications::Query.
      class Query
        attr_reader :scope

        def initialize(lead_provider:, filters: {})
          @scope = lead_provider
            .application_lead_providers
            .where(id: lead_provider.application_lead_providers.preferred_per_application)
            .joins(application: [:user, { course_cohort: :course }])
            .preload(
              application: [
                :user,
                { course_cohort: { course: :milestones } },
                { institution: :institutionable },
              ],
            )
            .order("applications.id")

          apply_filters(filters)
        end

        def application_lead_providers
          scope
        end

        def application_lead_provider(ecf_id:)
          scope.find_by!(applications: { ecf_id: })
        end

      private

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
          scope.merge!(Application.where(updated_at: time..)) if time
        end
      end
    end
  end
end
