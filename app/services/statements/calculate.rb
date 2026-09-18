# frozen_string_literal: true

module Statements
  class Calculate
    APPLICATION_SCOPES = %i[expected outstanding].freeze

    def initialize(statement:, scope: nil)
      @statement = statement
      @scope = scope&.to_sym
    end

    def course_cohorts
      @course_cohorts ||= statement.course_cohorts.includes(:course, :milestones).map do |course_cohort|
        CourseCohortCalculator.new(statement: @statement, course_cohort:)
      end
    end

    def applications_by_declaration_type
      raise ArgumentError, "scope must be one of: #{APPLICATION_SCOPES.join(", ")}" unless APPLICATION_SCOPES.include?(scope)

      grouping = {}

      course_cohorts.each do |ccc|
        ccc.funded_scopes.each do |milestone_scope|
          declaration_type = milestone_scope[:declaration_type]
          applications = milestone_scope.fetch(scope).includes(course_cohort: :cohort).to_a
          grouping[declaration_type] = Array(grouping[declaration_type]) + applications
        end
      end

      grouping
    end

    def summary_rows
      return @summary_rows if @summary_rows

      @summary_rows = declaration_types.map do |declaration_type|
        {
          declaration_type:,
          expected: course_cohorts.sum { |ccc| ccc.get_funded_scope(:expected, declaration_type:).size },
          received: course_cohorts.sum { |ccc| ccc.get_funded_scope(:received, declaration_type:).size },
          outstanding: course_cohorts.sum { |ccc| ccc.get_funded_scope(:outstanding, declaration_type:).size },
        }
      end

      @summary_rows << summarize(@summary_rows)
      @summary_rows
    end

    def get_funded(key, declaration_type:)
      row = summary_rows.detect { _1[:declaration_type] == declaration_type }
      row&.fetch(key)
    end

    def expected_output_payment
      @expected_output_payment ||= course_cohorts.sum do |ccc|
        ccc.funded_scopes.sum { |row| row[:expected_value] || 0 }
      end
    end

    def total_output_payment
      billable_declarations.sum(:value)
    end

    def total_voided
      statement.declarations.where(state: "voided").count
    end

    def total_clawbacks
      statement.clawback_declarations.sum(:value)
    end

    def total_adjustments
      statement.adjustments.sum(:amount)
    end

    def total_payment
      total_output_payment + total_clawbacks + total_adjustments + statement.reconcile_amount.to_f
    end

    def declaration_types
      course_cohorts.flat_map { |ccc| ccc.funded_scopes.map { |row| row[:declaration_type] } }.uniq
    end

  private

    attr_reader :statement, :scope

    def billable_declarations
      statement.declarations.billable
    end

    def summarize(rows)
      {
        declaration_type: "Total",
        expected: rows.sum { |row| row[:expected] },
        received: rows.sum { |row| row[:received] },
        outstanding: rows.sum { |row| row[:outstanding] },
      }
    end
  end
end
