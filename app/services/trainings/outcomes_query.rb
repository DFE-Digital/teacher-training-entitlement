module Trainings
  # Latest participant outcome per application, taken from the requesting provider's own
  # completed declarations that are billable or voidable (the same rule as
  # Declaration.eligible_for_outcomes), so previous providers' and voided declarations never leak.
  class OutcomesQuery
    def initialize(lead_provider:, application_ids:)
      @lead_provider = lead_provider
      @application_ids = application_ids
    end

    # => { application_id => ParticipantOutcome }
    def call
      outcomes
        .group_by { |outcome| outcome.declaration.application_id }
        .transform_values { |list| list.max_by { |o| [o.created_at, o.id] } }
    end

  private

    attr_reader :lead_provider, :application_ids

    def outcomes
      ParticipantOutcome
        .where(declaration: eligible_declarations)
        .includes(:declaration)
    end

    def eligible_declarations
      Declaration
        .completed
        .with_lead_provider(lead_provider)
        .billable_or_voidable
        .where(application_id: application_ids)
    end
  end
end
