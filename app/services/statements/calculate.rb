# frozen_string_literal: true

module Statements
  class Calculate
    def initialize(statement:)
      @statement = statement
    end

    def course_cohorts
      @course_cohorts ||= statement.course_cohorts.includes(:course, :milestones).map do |course_cohort|
        CourseCohortCalculator.new(statement: @statement, course_cohort:)
      end
    end

    def expected
      grouping = {}

      course_cohorts.each do |ccc|
        ccc.funded_scopes.each do |milestone_scope|
          declaration_type = milestone_scope[:declaration_type]
          grouping[declaration_type] = if grouping[declaration_type].nil?
                                         milestone_scope[:expected].includes(course_cohort: :cohort).to_a
                                       else
                                         grouping[declaration_type] + milestone_scope[:expected].includes(course_cohort: :cohort).to_a
                                       end
        end
      end

      grouping
    end

    def outstanding
      grouping = {}

      course_cohorts.each do |ccc|
        ccc.funded_scopes.each do |milestone_scope|
          declaration_type = milestone_scope[:declaration_type]
          grouping[declaration_type] = if grouping[declaration_type].nil?
                                         milestone_scope[:outstanding].includes(course_cohort: :cohort).to_a
                                       else
                                         grouping[declaration_type] + milestone_scope[:outstanding].includes(course_cohort: :cohort).to_a
                                       end
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

    attr_reader :statement

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
