module Statements
  class CourseCohortCalculator
    def initialize(statement:, course_cohort:)
      @statement = statement
      @course_cohort = course_cohort
      @contract = statement.lead_provider.contract(course_cohort:)
      @milestones = course_cohort.milestones.sort_by { |milestone| Milestone::DECLARATION_TYPES.index(milestone.declaration_type) }
      @course_name = course_cohort.course.name
    end

    attr_reader :statement, :contract, :course_name

    def funded_scopes
      @funded_scopes ||= milestones.map { |milestone| scopes(milestone:, funded_place: [true]) }
    end

    def self_funded_scopes
      @self_funded_scopes ||= milestones.map { |milestone| scopes(milestone:, funded_place: [nil, false]) }
    end

    def get_funded_scope(key, declaration_type:)
      funded_scope = funded_scopes.detect { _1[:declaration_type] == declaration_type }
      funded_scope&.fetch(key)
    end

    def summary_funded
      funded_scopes + [summarize(funded_scopes)]
    end

    def summary_self_funded
      self_funded_scopes + [summarize(self_funded_scopes)]
    end

  private

    attr_reader :course_cohort, :milestones

    def scopes(milestone:, funded_place:)
      MilestoneCourseCohortCalculator.new(
        statement:,
        course_cohort:,
        milestone:,
        funded_place:,
        contract:,
      ).scopes
    end

    def summarize(rows)
      {
        declaration_type: "Total",
        expected: rows.sum { |row| row[:expected].size },
        received: rows.sum { |row| row[:received].size },
        outstanding: rows.sum { |row| row[:outstanding].size },
        expected_value: rows.sum { |row| row[:expected_value] || 0 },
        received_value: rows.sum { |row| row[:received_value] || 0 },
      }
    end
  end
end
