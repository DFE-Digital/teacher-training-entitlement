# frozen_string_literal: true

RSpec.shared_context "with only started declarations" do
  let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
  let(:self_funded_apps) { create_list(:application, 1, :accepted, :without_funded_place, course_cohort:, lead_provider:) }
  let(:value) { BigDecimal(60) }
  let(:completed_value) { BigDecimal(40) }
  let(:funded_declarations) do
    funded_apps[1..2].map do |application|
      started_received(application:, statement:, milestone: course_cohort.started_milestone)
    end
  end
  let(:self_funded_declarations) do
    self_funded_apps.map do |application|
      started_received(application:, statement:, milestone: course_cohort.started_milestone)
    end
  end

  before do
    # course_cohort has 7 applications (4 funded, 2 rejected funded and 1 self-funded)
    # lead provider has 1 paid statement and 1 open statement for course_cohort
    # paid statement has 1 started declaration
    # open statement has 3 started declarations (2 funded, 1 self-funded)
    # completed milestone acceptance window is in the future so not expecting any completed declarations

    # create some rejected applications to ensure they are not counted
    create_list(:application, 2, :with_funded_place, course_cohort:, lead_provider:, status: Application::REJECTED)

    # out of scope for calculation
    started_received(application: funded_apps[0], statement: paid_statement, milestone: course_cohort.started_milestone)

    # in scope
    funded_declarations
    self_funded_declarations
  end
end

RSpec.shared_context "with started and completed declarations" do
  let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
  let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

  let(:value) { BigDecimal(60) }
  let(:completed_value) { BigDecimal(40) }
  let(:funded_started_declarations) do
    [started_received(application: funded_apps[3], statement:, milestone: started_milestone)]
  end
  let(:funded_completed_declarations) do
    funded_apps[0..2].map do |application|
      completed_received(application:, statement:, milestone: completed_milestone)
    end
  end
  let(:self_funded_completed_declarations) do
    self_funded_apps[0..0].map do |application|
      completed_received(application:, statement:, milestone: completed_milestone)
    end
  end

  before do
    # course_cohort has 6 applications (4 funded and 2 self-funded)
    # lead provider has 1 paid statement, 1 payable statement and 1 open statement for course_cohort
    # paid statement has 1 started declaration funded
    # payable statement has 3 started declarations (2 funded, 1 self-funded)
    # open statement has 1 started declarations (funded) and 4 completed declarations (3 funded, 1 self-funded)
    # completed milestone acceptance window is active so expecting completed declarations

    # out of scope for calculation
    started_received(application: funded_apps[0], statement: paid_statement, milestone: started_milestone)
    (funded_apps[1..2] + self_funded_apps[0..0]).each do |application|
      started_received(application:, statement: payable_statement, milestone: started_milestone)
    end

    # in scope
    funded_started_declarations
    funded_completed_declarations
    self_funded_completed_declarations
  end
end

RSpec.shared_context "with only completed declarations" do
  let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
  let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

  let(:value) { BigDecimal(60) }
  let(:completed_value) { BigDecimal(40) }
  let(:funded_completed_declarations) do
    funded_apps[1..3].map do |application|
      completed_received(application:, statement:, milestone: completed_milestone)
    end
  end
  let(:self_funded_completed_declarations) do
    self_funded_apps[0..0].map do |application|
      completed_received(application:, statement:, milestone: completed_milestone)
    end
  end

  before do
    # course_cohort has 6 applications (4 funded and 2 self-funded)
    # lead provider has 1 paid statement, 1 payable statement and 1 open statement for course_cohort
    # paid statement has 4 started declarations funded
    # payable statement has 2 started declarations (2 self-funded) and 1 completed declarations (1 funded, 1 self-funded)
    # open statement has 4 completed declarations (3 funded, 1 self-funded)
    # completed milestone acceptance window is active so expecting completed declarations

    # out of scope for calculation
    funded_apps.each do |application|
      started_received(application:, statement: paid_statement, milestone: started_milestone)
    end
    self_funded_apps.each do |application|
      started_received(application:, statement: payable_statement, milestone: started_milestone)
    end
    funded_apps[0..0].each do |application|
      completed_received(application:, statement: payable_statement, milestone: completed_milestone)
    end

    # in scope
    funded_completed_declarations
    self_funded_completed_declarations
  end
end

RSpec.shared_context "with clawback declaration" do
  let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
  let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

  let(:value) { BigDecimal(60) }
  let(:completed_value) { BigDecimal(40) }
  let(:funded_completed_declarations) do
    funded_apps[2..3].map do |application|
      completed_received(application:, statement:, milestone: completed_milestone)
    end
  end
  let(:self_funded_completed_declarations) do
    self_funded_apps[0..0].map do |application|
      completed_received(application:, statement:, milestone: completed_milestone)
    end
  end

  before do
    # course_cohort has 6 applications (4 funded and 2 self-funded)
    # lead provider has 1 paid statement, 1 payable statement and 1 open statement for course_cohort
    # paid statement has 4 started declarations funded
    # payable statement has 2 started declarations (2 self-funded) and 1 completed declarations (1 funded, 1 self-funded)
    # 1 paid started declaration is voided -> creates a clawback declaration on open statement
    # open statement has 3 completed declarations (2 funded, 1 self-funded) and 1 clawback declaration
    # completed milestone acceptance window is active so expecting completed declarations

    # out of scope for calculation
    funded_apps.each do |application|
      started_received(application:, statement: paid_statement, milestone: started_milestone)
    end
    self_funded_apps.each do |application|
      started_received(application:, statement: payable_statement, milestone: started_milestone)
    end
    funded_apps[0..0].each do |application|
      completed_received(application:, statement: payable_statement, milestone: completed_milestone)
    end

    # in scope for calculation
    clawback_received(funded_apps[1], milestone: started_milestone)
    funded_completed_declarations
    self_funded_completed_declarations
  end
end
