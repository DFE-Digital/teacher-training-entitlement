module Admin
  class CoursePaymentOverviewComponent < BaseComponent
    attr_reader :course_cohort, :statement

    delegate_missing_to :calculator

    def initialize(course_cohort:, statement:)
      @course_cohort = course_cohort
      @statement = statement
    end

    def calculator
      @calculator ||= ::Statements::Calculate.new(statement:)
    end

    def course_name
      course_cohort.course.name
    end

    def funded_rows
      started = funded_billable_count_for_type("started")
      completed = funded_billable_count_for_type("completed")
      [
        [t(".started"), started, output_payment_per_participant, started * output_payment_per_participant],
        [t(".completed"), completed, output_payment_per_participant, completed * output_payment_per_participant],
        [t(".total"), started + completed, nil, (started + completed) * output_payment_per_participant],
      ]
    end

    def self_funded_rows
      started = self_funded_billable_count_for_type("started")
      completed = self_funded_billable_count_for_type("completed")
      [
        [t(".started"), started],
        [t(".completed"), completed],
        [t(".total"), started + completed],
      ]
    end
  end
end
