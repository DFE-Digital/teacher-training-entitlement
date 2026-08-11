# frozen_string_literal: true

module Statements
  class CourseCalculator
    attr_reader :contract

    delegate :course,
             :recruitment_target,
             :statement,
             to: :contract

    def initialize(contract:)
      @contract = contract
    end

    def course_declarations
      statement.declarations
               .joins(application: :course_cohort)
               .where(course_cohorts: { course_id: contract.course_id })
    end

    def billable_declarations_count
      course_declarations.billable.count
    end

    def refundable_declarations_count
      course_declarations.joins(:clawback_declaration).count
    end

    def not_eligible_declarations_count
      course_declarations.where(state: %w[ineligible voided]).count
    end

    def refundable_declarations_by_type_count
      course_declarations.joins(:clawback_declaration).group(:declaration_type).count
    end

    def billable_declarations_count_for_declaration_type(declaration_type)
      scope = course_declarations.billable

      scope = if declaration_type == "retained"
                scope.where(declaration_type: %w[retained-1 retained-2])
              else
                scope.where(declaration_type:)
              end

      scope.count
    end

    def clawback_payment
      @clawback_payment ||= Statements::OutputPaymentCalculator.call(
        contract:,
        total_participants: refundable_declarations_count,
      )[:subtotal]
    end

    def output_payment_subtotal
      output_payment[:subtotal]
    end

    def expected_output_payment_subtotal
      expected_output_payment[:subtotal]
    end

    def allowed_declaration_types
      cohort_ids = course_declarations.joins(application: :course_cohort)
                                       .pluck("course_cohorts.cohort_id")
                                       .uniq

      Schedule.where(cohort_id: cohort_ids, course_group: course.course_group)
              .flat_map(&:allowed_declaration_types)
              .uniq
              .sort_by { Schedule::DECLARATION_TYPES.index(_1) }
    end

    def declaration_count_for_declaration_type(declaration_type)
      declaration_count_by_type.fetch(declaration_type, 0)
    end

    def funded_billable_count_for_type(declaration_type)
      course_declarations.billable
                         .joins(:application)
                         .where(applications: { funded_place: true })
                         .where(declaration_type:)
                         .count
    end

    def self_funded_billable_count_for_type(declaration_type)
      course_declarations.billable
                         .joins(:application)
                         .where(applications: { funded_place: [false, nil] })
                         .where(declaration_type:)
                         .count
    end

    def output_payment
      @output_payment ||= Statements::OutputPaymentCalculator.call(
        contract:,
        total_participants: billable_declarations_count,
      )
    end

    def output_payment_per_participant
      output_payment[:per_participant]
    end

    def service_fees_per_participant
      calculated_service_fee_per_participant_derived_from_monthly_service_fee || calculated_service_fee_per_participant
    end

    def monthly_service_fees
      return calculated_service_fee if contract.monthly_service_fee.nil?

      contract.monthly_service_fee
    end

    def course_total
      monthly_service_fees + output_payment_subtotal - clawback_payment
    end

  private

    delegate :service_fee_percentage, :service_fee_installments, :per_participant, to: :contract

    def calculated_service_fee_per_participant_derived_from_monthly_service_fee
      return unless contract.monthly_service_fee

      contract.monthly_service_fee / contract.recruitment_target
    end

    def calculated_service_fee_per_participant
      service_fees[:per_participant]
    end

    def calculated_service_fee
      service_fees[:monthly]
    end

    def service_fees
      @service_fees ||= ServiceFeesCalculator.call(contract:)
    end

    def declaration_count_by_type
      @declaration_count_by_type ||= course_declarations.billable.group(:declaration_type).count
    end

    def expected_output_payment
      @expected_output_payment ||= Statements::OutputPaymentCalculator.call(
        contract:,
        total_participants: recruitment_target,
      )
    end
  end
end
