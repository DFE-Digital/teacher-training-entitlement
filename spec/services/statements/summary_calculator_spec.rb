# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::SummaryCalculator, :revisit do
  let(:cohort) { create(:cohort, :has_targeted_delivery_funding) }
  let(:lead_provider) { create :lead_provider }
  let(:statement) { create(:statement, :next_output_fee, lead_provider:, reconcile_amount: 0, cohort:) }
  let(:application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:, cohort:) }
  let(:declaration_type) { "started" }

  let!(:course) { create(:course, :npd_eirt) }
  let!(:contract) { create(:contract, course:, statement:) }
  let(:contract_template_monthly_service_fee) { nil }

  subject { described_class.new(statement:) }

  before do
    create(:schedule, :tte_reception_autumn, cohort:)
  end

  describe "#total_payment" do
    let(:default_total) { BigDecimal("0.1212631578947368421052631578947368421064e4") }
    let(:expected_total_output_payment) { 160 }

    before { contract.contract_template.update! monthly_service_fee: contract_template_monthly_service_fee }

    context "when there is a positive reconcile_amount" do
      before { statement.update!(reconcile_amount: 1234) }

      it "increases total" do
        expect(subject.total_payment).to match_bigdecimal(default_total + 1234)
      end
    end

    context "when there is a negative reconcile_amount" do
      before { statement.update!(reconcile_amount: -1234) }

      it "descreases the total" do
        expect(subject.total_payment).to match_bigdecimal(default_total - 1234)
      end
    end

    context "when there are course output payments" do
      before { create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:) }

      it "adds the output payments to the total" do
        expect(subject.total_payment).to match_bigdecimal(default_total + expected_total_output_payment)
      end
    end

    context "when there are targeted delivery funding" do
      let(:application) do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
        )
      end

      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, declaration_type:, application:, lead_provider:, statement:)
        end
      end

      it "adds the targeted delivery funding to the total" do
        expect(subject.total_payment).to match_bigdecimal(default_total + expected_total_output_payment)
      end
    end

    context "when there are clawbacks" do
      before do
        awaiting_clawback = travel_to 2.months.ago do
          application

          earlier_statement =
            create(:statement, :next_output_fee, lead_provider:, cohort: application.cohort)

          create(:declaration, :paid, declaration_type:, application:, lead_provider:, statement: earlier_statement)
        end

        travel_to 1.month.from_now do
          create(:statement, :next_output_fee, lead_provider:, cohort: application.cohort)
          service = Declarations::Clawback.new(declaration: awaiting_clawback)
          service.call
          raise("Could not void: #{service.errors.full_messages}") if service.errors.any?
        end
      end

      let :application do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
        )
      end

      it "deducts the clawbacks from the total" do
        expect(subject.total_payment)
          .to match_bigdecimal(default_total)
      end
    end

    context "when there are adjustments" do
      let!(:adjustment_1) { create(:adjustment, statement:, amount: 100) }
      let!(:adjustment_2) { create(:adjustment, statement:, amount: -50) }

      it "adds adjustments to the total" do
        expect(subject.total_payment).to match_bigdecimal(default_total + adjustment_1.amount + adjustment_2.amount)
      end
    end
  end

  describe "#total_starts" do
    context "when there are no declarations" do
      it { expect(subject.total_starts).to be_zero }
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, lead_provider:, application:, statement:)
        end
      end

      context "with a billable declaration" do
        it "counts them" do
          expect(subject.total_starts).to eq(1)
        end
      end
    end

    context "when there are clawbacks" do
      before do
        declaration = travel_to(1.month.ago) do
          create(:declaration, :paid, lead_provider:, statement: paid_statement, cohort:)
        end

        statement

        travel_to statement.deadline_date do
          Declarations::Void.new(declaration:).void || raise("Could not void")
        end
      end

      let(:paid_statement) { create(:statement, :paid, lead_provider:) }

      let :statement do
        create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:, cohort:)
      end

      it "does not count them" do
        expect(statement.reload.statement_items.where(state: "awaiting_clawback")).to exist
        expect(subject.total_starts).to be_zero
      end
    end
  end

  describe "#total_completed" do
    let(:declaration_type) { "completed" }

    context "when there are no declarations" do
      it do
        expect(subject.total_completed).to be_zero
      end
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, declaration_type:, lead_provider:, application:, statement:)
        end
      end

      it "counts them" do
        expect(subject.total_completed).to eq(1)
      end
    end

    context "when there are clawbacks" do
      let(:paid_statement) { create(:statement, :paid, lead_provider:, cohort:) }
      let!(:declaration) do
        travel_to paid_statement.deadline_date do
          create(:declaration, :paid, declaration_type:, lead_provider:, application:, cohort:, statement: paid_statement)
        end
      end
      let!(:statement) { create(:statement, :next_output_fee, cohort:, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        expect(statement.statement_items.where(state: "awaiting_clawback")).to exist
        expect(subject.total_completed).to be_zero
      end
    end
  end

  describe "#total_retained" do
    let(:declaration_type) { "retained-1" }

    context "when there are no declarations" do
      it do
        expect(subject.total_retained).to be_zero
      end
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, declaration_type: "retained-1", application:, lead_provider:, statement:)
        end
      end

      it "counts them" do
        expect(subject.total_retained).to eq(1)
      end
    end

    context "when there are clawbacks" do
      let(:paid_statement) { create(:statement, :paid, lead_provider:, cohort:) }

      let!(:declaration) do
        travel_to paid_statement.deadline_date do
          create(:declaration, :paid, declaration_type: "retained-1", lead_provider:, application:, cohort:, statement: paid_statement)
        end
      end
      let!(:statement) { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:, cohort:) }

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        expect(statement.statement_items.where(state: "awaiting_clawback")).to exist
        expect(subject.total_retained).to be_zero
      end
    end
  end

  describe "#total_voided" do
    context "when there are no declarations" do
      it { expect(subject.total_voided).to be_zero }
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :voided, application:, lead_provider:, statement:)
        end
      end

      it "counts them" do
        expect(subject.total_voided).to eq(1)
      end
    end

    context "when there are multiple declarations for the same user" do
      before do
        user = create :user
        create(:declaration, :voided, lead_provider:, statement:, application: create(:application, user:))
        create(:declaration, :voided, lead_provider:, statement:, application: create(:application, user:))
        create(:declaration, :voided, lead_provider:, statement:)
      end

      it "counts them" do
        expect(subject.total_voided).to eq(3)
      end
    end
  end

  context "when there exists contracts over multiple cohorts" do
    let!(:cohort_2023) { create(:cohort, :next) }
    let!(:statement_2023) { create(:statement, lead_provider:, cohort: cohort_2023) }

    before do
      create(:contract, statement: statement_2023, course:)
      create(
        :declaration,
        :eligible,
        application:,
        statement: statement_2023,
      )
    end

    it "only includes declarations for the related cohort" do
      expect(described_class.new(statement:).total_starts).to be_zero
      expect(described_class.new(statement: statement_2023).total_starts).to be(1)
    end
  end

  describe "#total_clawbacks" do
    let(:application) do
      create(
        :application,
        :accepted,
        :eligible_for_funding,
        course:,
        lead_provider:,
        eligible_for_funding: true,
        cohort:,
      )
    end

    before do
      application.schedule.update! training_starts_at: statement.deadline_date - 1.month
      earlier_statement = create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:)

      awaiting_clawback = travel_to(earlier_statement.deadline_date) do
        create(:declaration, :paid, declaration_type:, application:, lead_provider:, statement:)
      end

      travel_to statement.deadline_date do
        Declarations::Void.new(declaration: awaiting_clawback).void || raise("Could not void")
      end
    end

    it "returns total clawbacks" do
      expect(subject.clawback_payments.to_f).to eq(160.0)
      expect(subject.total_clawbacks.to_f).to eq(160.0)
    end
  end

  describe "#total_adjustments" do
    before do
      create(:adjustment, statement:, amount: 100)
      create(:adjustment, statement:, amount: 200)
      create(:adjustment, amount: 400)
    end

    it "returns total adjustments" do
      expect(subject.total_adjustments.to_f).to eq(300)
    end
  end

  describe "Contract with special_course", :npq do
    let!(:maths_course) { create(:course, :leading_primary_mathematics) }
    let!(:leading_maths_contract) do
      create(
        :contract,
        statement:,
        course: maths_course,
      )
    end

    before do
      travel_to statement.deadline_date do
        create_list(:declaration, 3, :eligible, course:, lead_provider:, statement:)
        create_list(:declaration, 7, :eligible, course: maths_course, lead_provider:, statement:)
      end
    end

    context "when leading_maths_contract has special_course is false" do
      it "totals all course types" do
        expect(Contract.count).to be(2)
        expect(subject.total_starts.to_f).to eq(10)
        expect(subject.total_output_payment.to_f).to eq(160.0 * 10)
      end
    end

    context "when leading_maths_contract has special_course is true" do
      before do
        leading_maths_contract.contract_template.update!(special_course: true)
      end

      it "totals only totals course types that are not special" do
        expect(Contract.count).to be(2)
        expect(subject.total_starts.to_f).to eq(3)
        expect(subject.total_output_payment.to_f).to eq(160.0 * 3)
      end
    end
  end

  describe "#expected_starts" do
    it "returns sum of recruitment_target across contracts" do
      expect(subject.expected_starts).to eq(contract.recruitment_target)
    end
  end

  describe "#expected_completed" do
    it "equals total_starts" do
      expect(subject.expected_completed).to eq(subject.total_starts)
    end
  end

  describe "#outstanding_starts" do
    it "returns expected minus received, minimum zero" do
      expect(subject.outstanding_starts).to eq([subject.expected_starts - subject.total_starts, 0].max)
    end
  end

  describe "#outstanding_completed" do
    it "returns expected minus received, minimum zero" do
      expect(subject.outstanding_completed).to eq([subject.expected_completed - subject.total_completed, 0].max)
    end
  end

  describe "#expected_output_payment" do
    it "returns sum of expected output payments from course calculators" do
      expect(subject.expected_output_payment).to be_present
    end
  end

  describe "#total_declarations" do
    it "returns sum of starts and completed" do
      expect(subject.total_declarations).to eq(subject.total_starts + subject.total_completed)
    end
  end

  describe "#expected_total" do
    it "returns sum of expected starts and expected completed" do
      expect(subject.expected_total).to eq(subject.expected_starts + subject.expected_completed)
    end
  end

  describe "#outstanding_total" do
    it "returns sum of outstanding starts and outstanding completed" do
      expect(subject.outstanding_total).to eq(subject.outstanding_starts + subject.outstanding_completed)
    end
  end
end
