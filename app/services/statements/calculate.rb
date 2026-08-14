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

    def expected_output_payment = 0
    def total_output_payment = 0
    def total_voided = 0
    def total_clawbacks = 0
    def total_adjustments = 0
    def total_service_fees = 0
    def total_payment = 0
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
      statement.milestones.includes(:course_cohort).where(declaration_type:).map(&:course_cohort).uniq
    end

    def provider_applications(course_cohort)
      course_cohort.applications
        .joins(:current_application_lead_provider)
        .where(application_lead_providers: { lead_provider_id: statement.lead_provider_id })
    end
  end
end
