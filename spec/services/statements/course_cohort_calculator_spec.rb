require "rails_helper"

RSpec.describe Statements::CourseCohortCalculator do
  include Helpers::Declarations

  subject { described_class.new(statement:, course_cohort:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, name: "foo", identifier: "nth", lead_provider:) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:started_milestone) { course.milestones.detect(&:started_declaration_type?) }
  let(:completed_milestone) { course.milestones.detect(&:completed_declaration_type?) }

  let(:paid_statement) { create(:statement, :paid, lead_provider:) }
  let(:payable_statement) { create(:statement, :payable, lead_provider:) }
  let(:statement) { create(:statement, lead_provider:, start_date: Date.current.beginning_of_month, deadline_date: Date.current) }

  describe "with only started declarations" do
    include_context "with only started declarations"

    before do
      completed_milestone.update!(
        acceptance_window_start_offset: 4,
        acceptance_window_end_offset: 5,
      )
    end

    describe "for funded rows" do
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

      it do
        subject.summary_funded.zip(expected_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end

    describe "for self funded rows" do
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

      it do
        subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end
  end

  describe "with started and completed declarations" do
    include_context "with started and completed declarations"

    describe "for funded rows" do
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

      it do
        subject.summary_funded.zip(expected_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end

    describe "for self funded rows" do
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

      it do
        subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end
  end

  describe "with only completed declarations" do
    include_context "with only completed declarations"

    describe "for funded rows" do
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

      it do
        subject.summary_funded.zip(expected_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end

    describe "for self funded rows" do
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

      it do
        subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end
  end

  describe "with clawback declaration" do
    include_context "with clawback declaration"

    describe "for funded rows" do
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

      it do
        subject.summary_funded.zip(expected_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end

    describe "for self funded rows" do
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

      it do
        subject.summary_self_funded.zip(expected_self_funded).each do |row, expected_row|
          expect(row).to match_statement_row(expected_row)
        end
      end
    end
  end
end
