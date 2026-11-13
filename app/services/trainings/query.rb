module Trainings
  # Provider-visible training for API V2: only the provider's current assignments.
  class Query
    attr_reader :scope

    def initialize(lead_provider:, filters: {})
      @scope = lead_provider
        .application_lead_providers
        .current
        .joins(application: [:user, { course_cohort: :course }])
        .includes(
          application: [
            :user,
            { course_cohort: %i[course milestones] },
            { institution: :institutionable },
          ],
        )
        .order("applications.id")

      apply_filters(filters)
    end

    def application_lead_providers
      scope
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
      filter_by_teacher_email(filters[:teacher_email])
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
      scope.merge!(Application.where(eligible_for_funding: value)) unless value.nil?
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

    # The training email is currently the teacher's email, so both filters target users.email.
    def filter_by_teacher_email(emails)
      scope.merge!(User.where(email: emails)) if emails
    end

    def filter_by_updated_since(time)
      scope.merge!(Application.where(updated_at: time..)) if time
    end
  end
end
