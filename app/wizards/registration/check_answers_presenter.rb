module Registration
  # Collects the rows of the check answers page: the shared rows first, then
  # the rows of the course funding eligibility rule set.
  class CheckAnswersPresenter
    Row = Struct.new(:key, :value, :change_step)

    attr_reader :wizard, :rows

    delegate :state_store, to: :wizard

    def initialize(wizard)
      @wizard = wizard
      @rows = []
    end

    def add_row(key, value, change_step = nil)
      @rows << Row.new(key, value, change_step)
    end

    def call
      add_row("Course start", state_store.course_cohort&.name, :course_start_date)
      add_row("Course", wizard.course.name)
      add_row("Provider", state_store.lead_provider&.name, :choose_your_provider)
      FundingEligibilities.for_course(wizard.course).check_answer_rows(self)

      rows
    end
  end
end
