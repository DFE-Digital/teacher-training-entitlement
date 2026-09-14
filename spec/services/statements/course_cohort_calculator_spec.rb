require "rails_helper"

RSpec.describe Statements::CourseCohortCalculator do
  subject { described_class.new(statement:, course_cohort:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:, start_date: Date.current.beginning_of_month, deadline_date: Date.current) }
  let(:course_cohort) do
    create(:course_cohort, training_starts_at: 1.week.ago.to_date).tap do |course_cohort|
      create(:course_cohort_provider, course_cohort:, lead_provider:, teacher_funding: 100, recruitment_target: 20)
    end
  end
  let(:started_milestone) { create(:milestone, :started, course: course_cohort.course, payment_percentage: 0.6, acceptance_window_start_offset: 0, acceptance_window_end_offset: 14) }
  let!(:completed_milestone) { create(:milestone, :completed, course: course_cohort.course, payment_percentage: 0.4, acceptance_window_start_offset: 60, acceptance_window_end_offset: 90) }
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

  RSpec::Matchers.define :match_statement_row do |expected|
    match do |actual|
      @mismatches = {}
      @milestone = "milestone: #{expected[:declaration_type]}"
      expected.each do |key, expected_value|
        actual_value = actual[key]
        @mismatches[key] = { expected: expected_value, actual: actual_value } unless values_match_field?(expected_value, actual_value)
      end

      @mismatches.empty?
    end

    failure_message do
      details = @mismatches.map { |key, diff|
        <<~MSG
          row field #{key}:
            expected: #{format_field(diff[:expected])}
            actual:   #{format_field(diff[:actual])}
        MSG
      }.join("\n")

      [@milestone, details].join("\n")
    end

    def values_match_field?(expected_value, actual_value)
      if collection?(expected_value) || collection?(actual_value)
        ids(actual_value).sort == ids(expected_value).sort
      else
        actual_value == expected_value
      end
    end

    def collection?(value)
      value.is_a?(Enumerable) || value.is_a?(ActiveRecord::Relation)
    end

    def ids(value)
      return [] if value.nil?

      Array(value).map { |v| v.respond_to?(:id) ? v.id : v }
    end

    def format_field(value)
      collection?(value) ? ids(value).inspect : value.inspect
    end
  end

  describe "with only started declarations" do
    before do
      # course_cohort has 7 applications (4 funded, 2 rejected funded and 1 self-funded)
      # lead provider has 1 paid statement and 1 open statement for course_cohort
      # paid statement has 1 started declaration
      # open statement has 3 started declarations (2 funded, 1 self-funded)
      # completed milestone acceptance window is in the future so not expecting any completed declarations

      # create some rejected applications to ensure they are not counted
      create_list(:application, 2, :with_funded_place, course_cohort:, lead_provider:, status: Application::REJECTED)

      # out of scope for calculation
      started_received(application: funded_apps[0], statement: paid_statement, milestone: started_milestone)

      # in scope for calculation
    end

    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 1, :accepted, :without_funded_place, course_cohort:, lead_provider:) }
    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let!(:funded_declarations) do
      funded_apps[1..2].map do |application|
        started_received(application:, statement:, milestone: started_milestone)
      end
    end
    let!(:self_funded_declarations) do
      self_funded_apps.map do |application|
        started_received(application:, statement:, milestone: started_milestone)
      end
    end
    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: funded_apps[1..3], # 3 expecting only 3 because we deduct started declaration on previous statements
          received: funded_declarations,
          outstanding: funded_apps[3..3],
          value:,
          expected_value: 3 * value,
          received_value: 2 * value,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: [],
          received: [],
          outstanding: [],
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
          expected: [],
          received: self_funded_declarations,
          outstanding: [],
          expected_value: nil,
          received_value: nil,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: [],
          received: [],
          outstanding: [],
          expected_value: nil,
          received_value: nil,
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

    it "funded rows" do
      subject.summary_funded.zip(expected_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
      end
    end

    it "self funded rows" do
      subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
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
    end

    let!(:completed_milestone) { create(:milestone, :completed, course: course_cohort.course, payment_percentage: 0.4, acceptance_window_start_offset: 0, acceptance_window_end_offset: 14) }
    let(:payable_statement) { create(:statement, :payable, lead_provider:) }
    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let!(:funded_started_declarations) do
      [started_received(application: funded_apps[3], statement:, milestone: started_milestone)]
    end
    let!(:funded_completed_declarations) do
      funded_apps[0..2].map do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end
    let!(:self_funded_completed_declarations) do
      self_funded_apps[0..0].map do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end

    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: funded_apps[3..3],
          received: funded_started_declarations,
          outstanding: [],
          value:,
          expected_value: value,
          received_value: value,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: funded_apps,
          received: funded_completed_declarations,
          outstanding: funded_apps[3..3],
          value: completed_value,
          expected_value: 4 * completed_value,
          received_value: 3 * completed_value,
        },
        {
          declaration_type: "Total",
          expected: 5,
          received: funded_started_declarations.size + funded_completed_declarations.size,
          outstanding: funded_apps[3..3].size,
          expected_value: value + 4 * completed_value,
          received_value: value + 3 * completed_value,
        },
      ]
    end

    let(:expected_self_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: [],
          received: [],
          outstanding: [],
          expected_value: nil,
          received_value: nil,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: [],
          received: self_funded_completed_declarations,
          outstanding: [],
          expected_value: nil,
          received_value: nil,
        },
        {
          declaration_type: "Total",
          expected: 0,
          received: self_funded_completed_declarations.size,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
      ]
    end

    it "funded rows" do
      subject.summary_funded.zip(expected_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
      end
    end

    it "self funded rows" do
      subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
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
    end

    let!(:completed_milestone) { create(:milestone, :completed, course: course_cohort.course, payment_percentage: 0.4, acceptance_window_start_offset: 0, acceptance_window_end_offset: 14) }
    let(:payable_statement) { create(:statement, :payable, lead_provider:) }
    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let!(:funded_completed_declarations) do
      funded_apps[1..3].map do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end
    let!(:self_funded_completed_declarations) do
      self_funded_apps[0..0].map do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end

    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: [],
          received: [],
          outstanding: [],
          value:,
          expected_value: 0,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: funded_apps[1..3],
          received: funded_completed_declarations,
          outstanding: [],
          value: completed_value,
          expected_value: 3 * completed_value,
          received_value: 3 * completed_value,
        },
        {
          declaration_type: "Total",
          expected: 3,
          received: funded_completed_declarations.size,
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
          expected: [],
          received: [],
          outstanding: [],
          expected_value: nil,
          received_value: nil,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: [],
          received: self_funded_completed_declarations,
          outstanding: [],
          expected_value: nil,
          received_value: nil,
        },
        {
          declaration_type: "Total",
          expected: 0,
          received: self_funded_completed_declarations.size,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        },
      ]
    end

    it "funded rows" do
      subject.summary_funded.zip(expected_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
      end
    end

    it "self funded rows" do
      subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
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
    end

    let!(:completed_milestone) { create(:milestone, :completed, course: course_cohort.course, payment_percentage: 0.4, acceptance_window_start_offset: 0, acceptance_window_end_offset: 14) }
    let(:payable_statement) { create(:statement, :payable, lead_provider:) }
    let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:self_funded_apps) { create_list(:application, 2, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

    let(:value) { BigDecimal(60) }
    let(:completed_value) { BigDecimal(40) }
    let!(:funded_completed_declarations) do
      funded_apps[2..3].map do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end
    let!(:self_funded_completed_declarations) do
      self_funded_apps[0..0].map do |application|
        completed_received(application:, statement:, milestone: completed_milestone)
      end
    end

    let(:expected_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: funded_apps[1..1], # started declaration has been clawed back
          received: [],
          outstanding: funded_apps[1..1],
          value:,
          expected_value: value,
          received_value: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: funded_apps[1..3],
          received: funded_completed_declarations,
          outstanding: funded_apps[1..1],
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
          expected: [],
          received: [],
          outstanding: [],
          expected_value: nil,
          received_value: nil,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: [],
          received: self_funded_completed_declarations,
          outstanding: [],
          expected_value: nil,
          received_value: nil,
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

    it "funded rows" do
      subject.summary_funded.zip(expected_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
      end
    end

    it "self funded rows" do
      subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
      end
    end
  end
end
