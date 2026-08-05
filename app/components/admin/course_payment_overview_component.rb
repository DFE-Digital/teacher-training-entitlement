module Admin
  class CoursePaymentOverviewComponent < BaseComponent
    attr_reader :contract

    delegate_missing_to :calculator

    def initialize(contract:)
      @contract = contract
    end

    def calculator
      @calculator ||= ::Statements::CourseCalculator.new(contract:)
    end

    def course_name
      contract.course.name
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
