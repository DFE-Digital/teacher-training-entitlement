# frozen_string_literal: true

module Statements
  class Calculate
    def initialize(statement:)
      @statement = statement
      @cache = {}
    end

    def summary_rows
      return @summary_rows if @summary_rows

      @summary_rows = declaration_types.map do |declaration_type|
        {
          declaration_type:,
          expected: expected_for(declaration_type),
          total: total_for(declaration_type),
          outstanding: outstanding_for(declaration_type),
        }
      end
      @summary_rows << total_row(@summary_rows)
      @summary_rows
    end

    def expected_output_payment
      lead_provider_course_cohorts.sum do |course_cohort|
        contract = statement.lead_provider.contract(course_cohort:)
        total_expected * contract.teacher_funding
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

  private

    attr_reader :statement

    def declaration_types
      statement.milestones.pluck(:declaration_type).uniq
    end

    def cached(key)
      return @cache[key] if @cache[key]

      @cache[key] = yield if block_given?
    end

    def started?(declaration_type)
      declaration_type == Milestone::STARTED
    end

    def expected_for(declaration_type)
      cached(:"expected_for_#{declaration_type}") do
        course_cohorts_with_milestone(declaration_type).sum do |cc|
          provider_applications(cc).tap { |scope|
            started?(declaration_type) ? scope.has_been_accepted : scope.has_been_started
          }.count
        end
      end
    end

    def total_for(declaration_type)
      cached(:"total_for_#{declaration_type}") do
        billable_declarations.where(declaration_type:).count
      end
    end

    def outstanding_for(milestone)
      expected_for(milestone) - total_for(milestone)
    end

    def total_row(summary_rows)
      cached(:total_row) do
        {
          declaration_type: "Total",
          expected: summary_rows.sum { |row| row[:expected] },
          total: summary_rows.sum { |row| row[:total] },
          outstanding: summary_rows.sum { |row| row[:outstanding] },
        }
      end
    end

    def total_expected
      cached(:total_row)&.fetch(:expected)
    end

    def billable_declarations
      statement.declarations.billable
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
