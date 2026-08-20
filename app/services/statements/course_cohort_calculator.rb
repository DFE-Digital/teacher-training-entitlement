module Statements
  class CourseCohortCalculator
    def initialize(statement:, course_cohort:)
      @statement = statement
      @lead_provider = statement.lead_provider
      @course_cohort = course_cohort
      @contract = statement.lead_provider.contract(course_cohort:)
      @milestones = course_cohort.milestones
      @course_name = course_cohort.course.name
    end

    attr_reader :contract, :course_name

    def funded
      @funded ||= milestones.map { |milestone| calculate_row(milestone, funded_place: [true]) }
    end

    def self_funded
      @self_funded ||= milestones.map { |milestone| calculate_row(milestone, funded_place: [nil, false]) }
    end

    def get_funded(key, declaration_type:)
      funded_row = funded.detect { _1[:declaration_type] == declaration_type }
      funded_row&.fetch(key)
    end

    def funded_rows
      return @funded_rows if @funded_rows

      @funded_rows = funded
      @funded_rows << summarize(funded)
      @funded_rows
    end

    def self_funded_rows
      return @self_funded_rows if @self_funded_rows

      @self_funded_rows = self_funded
      @self_funded_rows << summarize(self_funded)
      @self_funded_rows
    end

  private

    attr_reader :statement, :lead_provider, :course_cohort, :milestones

    def calculate_row(milestone, funded_place:)
      received = received_for(milestone, funded_place:)
      if funded_place.all?
        expected = expected_for(milestone, funded_place:)
        value = value_for(milestone)
        {
          declaration_type: milestone.declaration_type,
          expected:,
          received:,
          outstanding: expected - received,
          value:,
          expected_value: expected * value,
          received_value: received * value,
        }
      else
        {
          declaration_type: milestone.declaration_type,
          expected: 0,
          received:,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        }
      end
    end

    def summarize(rows)
      {
        declaration_type: "Total",
        expected: rows.sum { |row| row[:expected] },
        received: rows.sum { |row| row[:received] },
        outstanding: rows.sum { |row| row[:outstanding] },
        expected_value: rows.sum { |row| row[:expected_value] },
        received_value: rows.sum { |row| row[:received_value] },
      }
    end

    def received_for(milestone, funded_place:)
      statement
        .declarations
        .billable
        .joins(:application)
        .where(milestone:, application: { funded_place: })
        .count
    end

    def value_for(milestone)
      return if milestone.payment_amount.blank?

      contract.teacher_funding * (milestone.payment_amount / 100)
    end

    def expected_for(milestone, funded_place:)
      return 0 if statement.deadline_date <= milestone.acceptance_window_start_date

      scope = provider_applications(funded_place:)
      if milestone.started_declaration_type?
        scope.where(status: [Application::ACCEPTED, Application::STARTED, Application::COMPLETED])
      else
        scope.where(status: [Application::STARTED, Application::COMPLETED])
      end

      forecast = scope.count - previous_declarations(milestone:)
      forecast.positive? ? forecast : 0
    end

    def provider_applications(funded_place:)
      course_cohort.applications
        .joins(:current_application_lead_provider)
        .where(funded_place:)
        .where(application_lead_providers: { lead_provider: })
    end

    def previous_declarations(milestone:)
      previous_statments = Statement
                             .includes(:declarations)
                             .where(lead_provider:)
                             .where.not(id: statement.id)
                             .where(declarations: { milestone: })
                             .all

      previous_statments.sum do |statement|
        statement.declarations.joins(:application).billable.where(milestone:, application: { funded_place: [true] }).count
      end
    end
  end
end
