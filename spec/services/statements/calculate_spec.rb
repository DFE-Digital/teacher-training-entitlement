require "rails_helper"

RSpec.describe Statements::Calculate do
  subject(:calculate) { described_class.new(statement:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:) }

  describe "#course_cohorts" do
    subject(:course_cohorts) { described_class.new(statement:).course_cohorts }

    let(:application) { create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
    let(:milestone) { create(:milestone, :started, payment_amount: 60) }
    let!(:course_cohort) do
      cc = milestone.course_cohort
      create(:course_cohort_provider, course_cohort: cc, lead_provider:, teacher_funding: 100, recruitment_target: 20)
      cc
    end

    before do
      application.update!(status: Application::STARTED)
      create(:declaration, :eligible, :started, application:, statement:, milestone:, lead_provider:, value: 60)
    end

    it "returns array of CourseCohortCalculator" do
      expect(course_cohorts.first).to be_a(Statements::CourseCohortCalculator)
    end
  end

  describe "#summary_rows" do
    before do
      allow(ccc_one).to receive(:funded).and_return(ccc_one_funded)
      allow(ccc_two).to receive(:funded).and_return(ccc_two_funded)
      allow(calculate).to receive(:course_cohorts).and_return(course_cohort_calculators) # rubocop:disable RSpec/SubjectStub
    end

    let(:ccp) { create(:course_cohort_provider, lead_provider:) }
    let(:course_cohort_calculators) { [ccc_one, ccc_two] }
    let(:ccc_one) do
      Statements::CourseCohortCalculator.new(statement:, course_cohort: ccp.course_cohort)
    end
    let(:ccc_two) do
      Statements::CourseCohortCalculator.new(statement:, course_cohort: ccp.course_cohort)
    end

    let(:ccc_one_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 1,
          received: 1,
          outstanding: 0,
          value: 10,
          expected_value: 10,
          received_value: 10,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 4,
          received: 3,
          outstanding: 1,
          value: 10,
          expected_value: 40,
          received_value: 30,
        },
      ]
    end

    let(:ccc_two_funded) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 3,
          received: 1,
          outstanding: 2,
          value: 10,
          expected_value: 10,
          received_value: 10,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 5,
          received: 5,
          outstanding: 0,
          value: 10,
          expected_value: 40,
          received_value: 30,
        },
      ]
    end

    let(:expected_rows) do
      [
        {
          declaration_type: Milestone::STARTED,
          expected: 4,
          received: 2,
          outstanding: 2,
        },
        {
          declaration_type: Milestone::COMPLETED,
          expected: 9,
          received: 8,
          outstanding: 1,
        },
        {
          declaration_type: "Total",
          expected: 13,
          received: 10,
          outstanding: 3,
        },
      ]
    end

    it "sum across course_cohorts for funded applications" do
      calculate.summary_rows.zip(expected_rows).each do |row, expected_row|
        expect(row).to eq(expected_row)
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
