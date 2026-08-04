# frozen_string_literal: true

module Statements
  class SummaryCalculator
    attr_reader :statement

    delegate :use_targeted_delivery_funding?, to: :statement

    def initialize(statement:)
      @statement = statement
    end

    def total_output_payment
      course_calculators.sum(&:output_payment_subtotal)
    end

    def total_service_fees
      course_calculators.sum(&:monthly_service_fees)
    end

    def clawback_payments
      course_calculators.sum(&:clawback_payment)
    end

    def total_clawbacks
      clawback_payments
    end

    def total_adjustments
      statement.adjustments.sum(&:amount)
    end

    def total_payment
      total_service_fees + total_output_payment - total_clawbacks + total_adjustments + statement.reconcile_amount.to_f
    end

    def total_starts
      course_calculators.sum { _1.billable_declarations_count_for_declaration_type("started") }
    end

    def total_retained
      course_calculators.sum { _1.billable_declarations_count_for_declaration_type("retained") }
    end

    def total_completed
      course_calculators.sum { _1.billable_declarations_count_for_declaration_type("completed") }
    end

    def total_voided
      statement.declarations.where(state: "voided").count
    end

    def expected_starts
      course_calculators.sum(&:recruitment_target)
    end

    def expected_completed
      total_starts
    end

    def outstanding_starts
      [expected_starts - total_starts, 0].max
    end

    def outstanding_completed
      [expected_completed - total_completed, 0].max
    end

    def expected_output_payment
      course_calculators.sum(&:expected_output_payment_subtotal)
    end

    def total_declarations
      total_starts + total_completed
    end

    def expected_total
      expected_starts + expected_completed
    end

    def outstanding_total
      outstanding_starts + outstanding_completed
    end

  private

    def course_calculators
      @course_calculators ||= contracts.map { CourseCalculator.new(contract: _1) }
    end

    def contracts
      statement.contracts
        .includes(:contract_template, :course)
        .where(contract_template: { special_course: false })
        .order("courses.identifier")
    end
  end
end
