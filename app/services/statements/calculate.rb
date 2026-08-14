# frozen_string_literal: true

module Statements
  class Calculate
    def initialize(statement:)
      @statement = statement
    end

    def expected_starts
      course_cohorts_with_milestone(Milestone::STARTED).sum { |cc| provider_applications(cc).has_been_accepted.count }
    end

    def expected_completed
      course_cohorts_with_milestone(Milestone::COMPLETED).sum { |cc| provider_applications(cc).has_been_started.count }
    end

    def expected_total
      expected_starts + expected_completed
    end

    def total_starts
      billable_declarations.started.count
    end

    def total_completed
      billable_declarations.completed.count
    end

    def total_declarations
      total_starts + total_completed
    end

    def outstanding_starts
      [expected_starts - total_starts, 0].max
    end

    def outstanding_completed
      [expected_completed - total_completed, 0].max
    end

    def outstanding_total
      outstanding_starts + outstanding_completed
    end

    def expected_output_payment
      lead_provider_course_cohorts.sum do |course_cohort|
        computed = ComputedContract.draw(lead_provider: statement.lead_provider, course_cohort:)
        (computed.recruitment_target || 0) * (computed.teacher_funding || 0)
      end
    end

    def total_output_payment
      billable_declarations.sum(:value).to_f
    end

    def total_voided
      declarations.where(state: "voided").count
    end

    def total_clawbacks
      statement.clawback_declarations.sum(:value).to_f.abs
    end

    def total_adjustments
      statement.adjustments.sum(&:amount)
    end

    def total_service_fees = 0

    def total_payment
      total_output_payment - total_clawbacks + total_adjustments + statement.reconcile_amount.to_f
    end

    def total_retained = 0

    def funded_billable_count_for_type(_declaration_type) = 0
    def self_funded_billable_count_for_type(_declaration_type) = 0
    def output_payment_per_participant = 0

  private

    attr_reader :statement

    def declarations
      statement.declarations
    end

    def billable_declarations
      declarations.billable
    end

    def course_cohorts_with_milestone(declaration_type)
      statement.course_cohorts.joins(:milestones).where(milestones: { declaration_type: }).distinct
    end

    def provider_applications(course_cohort)
      course_cohort.applications
        .joins(:current_application_lead_provider)
        .where(application_lead_providers: { lead_provider_id: statement.lead_provider_id })
    end

    def lead_provider_course_cohorts
      statement.course_cohorts
        .joins(:course_cohort_providers)
        .where(course_cohort_providers: { lead_provider_id: statement.lead_provider_id })
        .distinct
    end
  end
end
