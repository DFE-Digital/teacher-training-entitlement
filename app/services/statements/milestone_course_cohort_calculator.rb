module Statements
  class MilestoneCourseCohortCalculator
    def initialize(statement:, course_cohort:, milestone:, funded_place:, contract:)
      @statement = statement
      @lead_provider = statement.lead_provider
      @course_cohort = course_cohort
      @milestone = milestone
      @funded_place = funded_place
      @contract = contract
    end

    def row
      received = received_count

      return self_funded_row(received:) unless funded?

      expected = expected_count
      value = value_for_milestone
      {
        declaration_type: milestone.declaration_type,
        expected:,
        received:,
        outstanding: expected - received,
        value:,
        expected_value: (value ? expected * value : nil),
        received_value: (value ? received * value : nil),
      }
    end

  private

    attr_reader :statement, :lead_provider, :course_cohort, :milestone, :funded_place, :contract

    def funded?
      funded_place.all?
    end

    def self_funded_row(received:)
      {
        declaration_type: milestone.declaration_type,
        expected: 0,
        received:,
        outstanding: 0,
        expected_value: 0,
        received_value: 0,
      }
    end

    def received_count
      statement
        .declarations
        .billable
        .joins(:application)
        .where(milestone:, application: { funded_place: })
        .count
    end

    def value_for_milestone
      return if milestone.payment_amount.blank?

      contract.teacher_funding * (milestone.payment_amount / 100)
    end

    def expected_count
      return 0 if statement.deadline_date <= milestone.acceptance_window_start_date

      forecast = provider_applications_count - previous_declarations_count
      forecast.positive? ? forecast : 0
    end

    def provider_applications_count
      scope = course_cohort.applications
        .joins(:current_application_lead_provider)
        .where(funded_place:)
        .where(application_lead_providers: { lead_provider: })

      if milestone.started_declaration_type?
        scope.where(status: [Application::ACCEPTED, Application::STARTED, Application::COMPLETED]).count
      else
        scope.where(status: [Application::STARTED, Application::COMPLETED]).count
      end
    end

    def previous_declarations_count
      previous_statements = Statement
        .includes(:declarations)
        .where(lead_provider:)
        .where.not(id: statement.id)
        .where(declarations: { milestone: })
        .all

      previous_statements.sum do |statement|
        statement.declarations.joins(:application).billable.where(milestone:, application: { funded_place: [true] }).count
      end
    end
  end
end
