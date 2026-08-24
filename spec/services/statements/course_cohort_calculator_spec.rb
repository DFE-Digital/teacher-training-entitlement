require "rails_helper"

RSpec.describe Statements::CourseCohortCalculator do
  subject { described_class.new(statement:, course_cohort:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:, start_date: Date.current.beginning_of_month, deadline_date: Date.current) }
  let(:started_milestone) { create(:milestone, :started, payment_amount: 60) }
  let(:course_cohort) do
    cc = started_milestone.course_cohort
    create(:course_cohort_provider, course_cohort: cc, lead_provider:, teacher_funding: 100, recruitment_target: 20)
    cc
  end
  let!(:completed_milestone) { create(:milestone, :completed, course_cohort:, payment_amount: 40, acceptance_window_start_date: 2.months.from_now) }
  let(:paid_statement) { create(:statement, :paid, lead_provider:) }

  def started_received(application:, statement:, milestone:)
    application.update!(status: Application::STARTED)
    create(
      :declaration, :eligible, :started,
      application:,
      statement:,
      milestone:,
      lead_provider: statement.lead_provider,
      value: 60
    )
  end

  def completed_received(application:, statement:, milestone:)
    application.update!(status: Application::COMPLETED)
    create(
      :declaration, :eligible, :completed,
      application:,
      statement:,
      milestone:,
      lead_provider: statement.lead_provider,
      value: 60
    )
  end

  def clawback_received(application, milestone:)
    declaration = application.declarations.find_by(milestone:)
    declaration.clawback!
  end

  describe "with only started declarations" do
    before do
      # course_cohort has 5 applications (4 funded and 1 self-funded)
      # lead provider has 1 paid statement and 1 open statement for course_cohort
      # paid statement has 1 started declaration
      # open statement has 3 started declarations (2 funded, 1 self-funded)
      # completed milestone acceptance window is in the future so not expecting any completed declarations

      # out of scope for calculation
      started_received(application: funded_apps[0], statement: paid_statement, milestone: started_milestone)

      # in scope for calculation
      (funded_apps[1..2] + self_funded_apps).each do |application|
        started_received(application:, statement:, milestone: started_milestone)
      end
    end

    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 1, :accepted, :without_funded_place, course_cohort:, lead_provider:) }
    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 3, # expecting only 3 because we deduct started declaration on previous statements
          received: 2,
          outstanding: 1,
          value:,
          expected_value: 3 * value,
          received_value: 2 * value,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 0,
          received: 0,
          outstanding: 0,
          value: completed_value,
          expected_value: 0.0,
          received_value: 0.0,
        },
        {
          declaration_type: "Total",
          expected: 3,
          received: 2,
          outstanding: 1,
          expected_value: 3 * value,
          received_value: 2 * value,
        },
      ]
    end

    let(:expected_self_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 0,
          received: 0,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: "Total",
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
      ]
    end

    it do
      subject.funded_rows.zip(expected_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end

      subject.self_funded_rows.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end
    end
  end

  describe "with started and completed declarations" do
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

      # in scope for calculation
      started_received(application: funded_apps[3], statement:, milestone: started_milestone)
      (funded_apps[0..2] + self_funded_apps[0..0]).each do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end

    let!(:completed_milestone) { create(:milestone, :completed, course_cohort:, payment_amount: 40, acceptance_window_start_date: 1.day.ago) }
    let(:payable_statement) { create(:statement, :payable, lead_provider:) }
    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 1,
          received: 1,
          outstanding: 0,
          value:,
          expected_value: value,
          received_value: value,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 4,
          received: 3,
          outstanding: 1,
          value: completed_value,
          expected_value: 4 * completed_value,
          received_value: 3 * completed_value,
        },
        {
          declaration_type: "Total",
          expected: 5,
          received: 4,
          outstanding: 1,
          expected_value: value + 4 * completed_value,
          received_value: value + 3 * completed_value,
        },
      ]
    end

    let(:expected_self_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 0,
          received: 0,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: "Total",
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
      ]
    end

    it do
      subject.funded_rows.zip(expected_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end
      subject.self_funded_rows.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end
    end
  end

  describe "with only completed declarations" do
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

      # in scope for calculation
      (funded_apps[1..3] + self_funded_apps[0..0]).each do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end

    let!(:completed_milestone) { create(:milestone, :completed, course_cohort:, payment_amount: 40, acceptance_window_start_date: 1.day.ago) }
    let(:payable_statement) { create(:statement, :payable, lead_provider:) }
    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 0,
          received: 0,
          outstanding: 0,
          value:,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 3,
          received: 3,
          outstanding: 0,
          value: completed_value,
          expected_value: 3 * completed_value,
          received_value: 3 * completed_value,
        },
        {
          declaration_type: "Total",
          expected: 3,
          received: 3,
          outstanding: 0,
          expected_value: 3 * completed_value,
          received_value: 3 * completed_value,
        },
      ]
    end

    let(:expected_self_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 0,
          received: 0,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: "Total",
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
      ]
    end

    it do
      subject.funded_rows.zip(expected_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end
      subject.self_funded_rows.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end
    end
  end

  describe "with clawback declaration" do
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
      (funded_apps[2..3] + self_funded_apps[0..0]).each do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end

    let!(:completed_milestone) { create(:milestone, :completed, course_cohort:, payment_amount: 40, acceptance_window_start_date: 1.day.ago) }
    let(:payable_statement) { create(:statement, :payable, lead_provider:) }
    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 1,
          received: 0,
          outstanding: 1,
          value:,
          expected_value: value,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 3,
          received: 2,
          outstanding: 1,
          value: completed_value,
          expected_value: 3 * completed_value,
          received_value: 2 * completed_value,
        },
        {
          declaration_type: "Total",
          expected: 4,
          received: 2,
          outstanding: 2,
          expected_value: value + 3 * completed_value,
          received_value: 2 * completed_value,
        },
      ]
    end

    let(:expected_self_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 0,
          received: 0,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: "Total",
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
      ]
    end

    it do
      subject.funded_rows.zip(expected_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end
      subject.self_funded_rows.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to eq(expected_row)
      end
    end
  end
end
