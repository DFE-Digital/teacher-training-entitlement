require "rails_helper"

RSpec.describe Statements::Calculate do
  subject(:calculate) { described_class.new(statement:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:) }
  let!(:started_milestone) { create(:milestone, :started) }
  let!(:course_cohort) { started_milestone.course_cohort }
  let!(:completed_milestone) { create(:milestone, :completed, course_cohort:) }

  describe "#summary_rows" do
    let(:summary_rows) { calculate.summary_rows }
    let(:total_rejected) { 1 }
    let(:total_accepted) { 13 }

    let(:started_row) do
      summary_rows.detect { _1[:declaration_type] == Milestone::STARTED }
    end
    let(:completed_row) do
      summary_rows.detect { _1[:declaration_type] == Milestone::COMPLETED }
    end
    let(:total_row) do
      summary_rows.detect { _1[:declaration_type] == "Total" }
    end

    let(:accepted_applications) do
      create_list(:application, total_accepted, :accepted, course_cohort:, lead_provider:)
    end
    let(:rejected_applications) do
      create_list(:application, total_rejected, :rejected, course_cohort:, lead_provider:)
    end

    let!(:contract) do
      course_cohort
        .course_cohort_providers
        .create!(lead_provider:, recruitment_target: 10, teacher_funding: 100)
    end

    let(:expected_output_payment) do
      expected_total_row[:expected] * contract.teacher_funding
    end

    def started_declaration_received!(application:, statement:, milestone:)
      application.update!(status: Application::STARTED)
      create(:declaration, :started, :eligible, statement:, application:, milestone:)
    end

    def completed_declaration_received!(application:, statement:, milestone:)
      application.update!(status: Application::COMPLETED)
      create(:declaration, :completed, :eligible, statement:, application:, milestone:)
    end

    context "with only started declarations" do
      before do
        statement
        accepted_applications.take(total_started).each do |application|
          started_declaration_received!(application:, statement:, milestone: started_milestone)
        end
      end

      let(:total_started) { 4 }
      let(:expected_started_row) do
        {
          declaration_type: Milestone::STARTED,
          expected: total_accepted,
          total: total_started,
          outstanding: total_accepted - total_started,
        }
      end

      let(:expected_total_row) do
        {
          declaration_type: "Total",
          expected: total_accepted,
          total: total_started,
          outstanding: total_accepted - total_started,
        }
      end

      it do
        expect(started_row).to eq(expected_started_row)
        expect(completed_row).to be_nil
        expect(total_row).to eq(expected_total_row)
        expect(summary_rows.map { _1[:declaration_type] }).to contain_exactly(Milestone::STARTED, "Total")
        expect(subject.expected_output_payment).to eq(expected_output_payment)
      end
    end

    context "with only started declarations and some applications were started in a previous statement" do
      before do
        previous_statement = create(:statement, :payable, lead_provider:)
        started_applications = accepted_applications.take(previous_total_started).map do |application|
          started_declaration_received!(application:, statement: previous_statement, milestone: started_milestone)
          application
        end

        statement
        (accepted_applications - started_applications).take(total_started).map do |application|
          started_declaration_received!(application:, statement:, milestone: started_milestone)
        end
      end

      let(:previous_total_started) { 4 }
      let(:total_started) { 8 }
      let(:expected_started_row) do
        {
          declaration_type: Milestone::STARTED,
          expected: total_accepted - previous_total_started,
          total: total_started,
          outstanding: (total_accepted - previous_total_started) - total_started,
        }
      end

      let(:expected_total_row) do
        {
          declaration_type: "Total",
          expected: total_accepted - previous_total_started,
          total: total_started,
          outstanding: (total_accepted - previous_total_started) - total_started,
        }
      end

      it do
        expect(started_row).to eq(expected_started_row)
        expect(completed_row).to be_nil
        expect(total_row).to eq(expected_total_row)
        expect(summary_rows.map { _1[:declaration_type] }).to contain_exactly(Milestone::STARTED, "Total")
        expect(subject.expected_output_payment).to eq(expected_output_payment)
      end
    end

    context "with started and completed declarations and some applications were started in a previous statement" do
      before do
        previous_statement = create(:statement, :payable, lead_provider:)
        started_applications = accepted_applications.take(previous_total_started).map do |application|
          started_declaration_received!(application:, statement: previous_statement, milestone: started_milestone)
          application
        end

        statement
        (accepted_applications - started_applications).take(total_started).each do |application|
          started_declaration_received!(application:, statement:, milestone: started_milestone)
        end

        started_applications.take(total_completed).each do |application|
          completed_declaration_received!(application:, statement:, milestone: completed_milestone)
        end
      end

      let(:previous_total_started) { 12 }
      let(:total_started) { 1 }
      let(:total_completed) { 3 }

      let(:expected_started_row) do
        {
          declaration_type: Milestone::STARTED,
          expected: total_accepted - previous_total_started,
          total: total_started,
          outstanding: (total_accepted - previous_total_started) - total_started,
        }
      end

      let(:expected_completed_row) do
        {
          declaration_type: Milestone::COMPLETED,
          expected: total_accepted,
          total: total_completed,
          outstanding: total_accepted - total_completed,
        }
      end

      let(:expected_total_row) do
        {
          declaration_type: "Total",
          expected: expected_started_row[:expected] + expected_completed_row[:expected],
          total: total_started + total_completed,
          outstanding: expected_started_row[:outstanding] + expected_completed_row[:outstanding],
        }
      end

      it do
        expect(started_row).to eq(expected_started_row)
        expect(completed_row).to eq(expected_completed_row)
        expect(total_row).to eq(expected_total_row)
        expect(summary_rows.map { _1[:declaration_type] }).to contain_exactly(Milestone::STARTED, Milestone::COMPLETED, "Total")
        expect(subject.expected_output_payment).to eq(expected_output_payment)
      end
    end

    context "with only completed declarations" do
      before do
        previous_statement = create(:statement, :payable, lead_provider:)
        started_applications = accepted_applications.take(total_started).map do |application|
          started_declaration_received!(application:, statement: previous_statement, milestone: started_milestone)
          application
        end
        previous_completed = started_applications.take(previous_total_completed).map do |application|
          completed_declaration_received!(application:, statement: previous_statement, milestone: completed_milestone)
          application
        end

        statement
        (started_applications - previous_completed).take(total_completed).each do |application|
          completed_declaration_received!(application:, statement:, milestone: completed_milestone)
        end
      end

      let(:total_started) { 13 }
      let(:previous_total_completed) { 3 }
      let(:total_completed) { 10 }

      let(:expected_completed_row) do
        {
          declaration_type: Milestone::COMPLETED,
          expected: total_started - previous_total_completed,
          total: total_completed,
          outstanding: (total_started - previous_total_completed) - total_completed,
        }
      end

      let(:expected_total_row) do
        {
          declaration_type: "Total",
          expected: total_started - previous_total_completed,
          total: total_completed,
          outstanding: (total_started - previous_total_completed) - total_completed,
        }
      end

      it do
        expect(started_row).to be_nil
        expect(completed_row).to eq(expected_completed_row)
        expect(total_row).to eq(expected_total_row)
        expect(summary_rows.map { _1[:declaration_type] }).to contain_exactly(Milestone::COMPLETED, "Total")
        expect(subject.expected_output_payment).to eq(expected_output_payment)
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
