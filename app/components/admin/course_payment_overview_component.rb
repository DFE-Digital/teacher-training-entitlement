module Admin
  class CoursePaymentOverviewComponent < BaseComponent
    attr_reader :statement, :calculator

    delegate :funded_rows,
             :self_funded_rows,
             :contract,
             :course_name,
             to: :calculator

    def initialize(statement:, course_cohort_calculator:)
      @statement = statement
      @calculator = course_cohort_calculator
    end
  end
end
