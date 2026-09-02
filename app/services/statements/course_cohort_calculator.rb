module Statements
  class CourseCohortCalculator
    def initialize(statement:, course_cohort:)
      @statement = statement
      @course_cohort = course_cohort
      @contract = statement.lead_provider.contract(course_cohort:)
      @milestones = course_cohort.milestones
      @course_name = course_cohort.course.name
    end

    attr_reader :contract, :course_name

    def funded
      @funded ||= milestones.map { |milestone| calculate_row(milestone:, funded_place: [true]) }
    end

    def self_funded
      @self_funded ||= milestones.map { |milestone| calculate_row(milestone:, funded_place: [nil, false]) }
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

    attr_reader :statement, :course_cohort, :milestones

    def calculate_row(milestone:, funded_place:)
      MilestoneCourseCohortCalculator.new(
        statement:,
        course_cohort:,
        milestone:,
        funded_place:,
        contract:,
      ).row
    end

    def summarize(rows)
      {
        declaration_type: "Total",
        expected: rows.sum { |row| row[:expected] },
        received: rows.sum { |row| row[:received] },
        outstanding: rows.sum { |row| row[:outstanding] },
        expected_value: rows.sum { |row| row[:expected_value] || 0 },
        received_value: rows.sum { |row| row[:received_value] || 0 },
      }
    end
  end
end
