require "rails_helper"

RSpec.describe Statements::Calculate do
  include Helpers::Declarations

  subject(:calculate) { described_class.new(statement:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:, start_date: Date.current.beginning_of_month, deadline_date: Date.current) }

  describe "#course_cohorts" do
    subject(:course_cohorts) { described_class.new(statement:).course_cohorts }

    let(:application) { create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:milestone) { course_milestone(course_cohort.course, :started) }
    let!(:course_cohort) do
      create(:course_cohort).tap do |course_cohort|
        create(:course_cohort_provider, course_cohort:, lead_provider:, teacher_funding: 100, recruitment_target: 20)
      end
    end

    before do
      started_received(application:, statement:, milestone:)
    end

    it "returns array of CourseCohortCalculator" do
      expect(course_cohorts.first).to be_a(Statements::CourseCohortCalculator)
    end
  end

  describe "#summary_rows across multiple course_cohorts" do
    include_context "with started and completed declarations"

    before do
      send_course = create(:course, name: "npd send", identifier: "npd-s", lead_provider:)
      send_course_cohort = send_course.course_cohorts.first
      milestone = send_course.milestones.detect(&:started_declaration_type?)
      create_list(:application, number_of_other_course_apps, :accepted, :with_funded_place, course_cohort: send_course_cohort, lead_provider:).each do |application|
        started_received(application:, statement:, milestone:)
      end
    end

    let(:number_of_other_course_apps) { 1 }
    let(:course) { create(:course, name: "npd reception", identifier: "npd-r", lead_provider:) }
    let(:started_milestone) { course.milestones.detect(&:started_declaration_type?) }
    let(:completed_milestone) { course.milestones.detect(&:completed_declaration_type?) }
    let(:course_cohort) { course.course_cohorts.first }
    let(:paid_statement) { create(:statement, :paid, lead_provider:) }
    let(:payable_statement) { create(:statement, :payable, lead_provider:) }
    let(:expected_rows) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 1 + number_of_other_course_apps,
          received: 1 + number_of_other_course_apps,
          outstanding: 0,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 4 + number_of_other_course_apps,
          received: 3,
          outstanding: 1 + number_of_other_course_apps,
        },
        {
          declaration_type: "Total",
          expected: 5 + 2 * number_of_other_course_apps,
          received: 4 + number_of_other_course_apps,
          outstanding: 1 + number_of_other_course_apps,
        },
      ]
    end

    it "sum across course_cohorts for funded applications" do
      calculate.summary_rows.zip(expected_rows).each do |row, expected_row|
        expect(row).to match_statement_row(expected_row)
      end
    end
  end

  describe "#total_output_payment" do
    it "sums billable declaration values" do
      create(:declaration, :eligible, statement:, value: 100)
      create(:declaration, :eligible, statement:, value: 50)

      expect(subject.total_output_payment).to eq(150.0)
    end

    it "returns zero when no declarations" do
      expect(subject.total_output_payment).to eq(0.0)
    end
  end

  describe "#total_clawbacks" do
    it "sums clawback declaration values" do
      create(:clawback_declaration, statement:, value: 100)
      create(:clawback_declaration, statement:, value: 60)

      expect(subject.total_clawbacks).to eq(160.0)
    end

    it "returns zero when no clawbacks" do
      expect(subject.total_clawbacks).to eq(0.0)
    end
  end

  describe "#total_adjustments" do
    it "sums adjustment amounts" do
      create(:adjustment, statement:, amount: 100)
      create(:adjustment, statement:, amount: 200)

      expect(subject.total_adjustments).to eq(300)
    end
  end

  describe "#total_voided" do
    before do
      create(:declaration, :voided, statement:)
    end

    it "counts voided declarations" do
      expect(subject.total_voided).to eq(1)
    end
  end

  describe "#total_payment" do
    it "calculates total as output + clawbacks + adjustments + reconcile" do
      create(:declaration, :eligible, statement:, value: 500)
      create(:clawback_declaration, statement:, value: -100)
      create(:adjustment, statement:, amount: 50)
      statement.update!(reconcile_amount: 25)

      expect(subject.total_payment).to eq(475.0)
    end
  end
end
