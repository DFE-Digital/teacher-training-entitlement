module Admin
  class CoursePaymentOverviewComponent < BaseComponent
    attr_reader :statement, :course_cohort

    delegate :funded_rows, :self_funded_rows, to: :calculator

    def initialize(statement:, course_cohort:)
      @statement = statement
      @course_cohort = course_cohort
    end

    def course_name
      course_cohort.course.name
    end

    def contract
      @statement.lead_provider.contract(course_cohort: @course_cohort)
    end

  private

    def calculator
      @calculator ||= Statements::CourseCohortCalculator.new(statement:, course_cohort:)
    end
  end
end
