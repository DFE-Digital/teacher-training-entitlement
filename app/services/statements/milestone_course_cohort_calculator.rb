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

    def scopes
      value = value_for_milestone
      {
        declaration_type: milestone.declaration_type,
        expected:,
        received:,
        outstanding:,
        value:,
        expected_value: value_of(expected, value),
        received_value: value_of(received, value),
      }
    end

  private

    attr_reader :statement, :lead_provider, :course_cohort, :milestone, :funded_place, :contract

    def forecasted_applications_declaration
      # returns application scope of forecast applications to receive a declaration
      #  for course_cohort for milestone
      scope = course_cohort.applications
        .joins(:current_application_lead_provider)
                .includes(:course_cohort, :user)
                .where(funded_place:)
        .where(application_lead_providers: { lead_provider: })

      if milestone.started_declaration_type?
        scope.where(status: [Application::ACCEPTED, Application::STARTED, Application::COMPLETED])
      else
        scope.where(status: [Application::STARTED, Application::COMPLETED])
      end
    end

    def received_applications_declaration
      # returns application scope of application with a declaration in previous statement
      previous_statements = Statement
        .includes(:declarations)
        .where(lead_provider:)
        .where.not(id: statement.id)
        .where(declarations: { milestone: })

      scope = Application.none
      previous_statements.each do |statement|
        application_ids = statement.declarations
          .includes(:application)
          .billable
          .where(milestone:, application: { funded_place: [true] })
          .pluck(:application_id)

        statement_scope = Application.where(id: application_ids)
        if scope.none?
          scope = statement_scope
        else
          scope.merge!(statement_scope)
        end
      end

      scope
    end

    def expected
      return Application.none unless funded?
      return Application.none if statement.deadline_date <= milestone.acceptance_window_start_date

      forecast = forecasted_applications_declaration.where.not(id: received_applications_declaration)
      forecast.none? ? Application.none : forecast
    end

    def received
      statement
        .declarations
        .billable
        .includes(application: :user, course_cohort: :cohort)
        .where(milestone:, application: { funded_place: })
    end

    def outstanding
      return Application.none if expected.none?

      expected.where.not(id: received.pluck(:application_id))
    end

    def value_of(scope, value)
      return unless value
      return 0 if scope.none?

      scope.size * value if value
    end

    def funded?
      funded_place.all?
    end

    def value_for_milestone
      return unless funded?
      return if milestone.payment_amount.blank?

      contract.teacher_funding * (milestone.payment_amount / 100)
    end
  end
end
