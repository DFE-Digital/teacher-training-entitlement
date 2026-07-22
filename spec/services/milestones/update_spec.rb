require "rails_helper"

RSpec.describe Milestones::Update, type: :model do
  subject(:service) do
    described_class.new(
      milestone:,
      statement_date:,
      acceptance_window_start_date:,
      acceptance_window_end_date:,
      payment_amount:,
    )
  end

  before do
    create(:statement, lead_provider: LeadProvider.last, cohort:, year: cohort.start_year, month: new_statement_month, output_fee: true)
    subject.call
  end

  let(:course_cohort) { create(:course_cohort) }
  let(:cohort) { course_cohort.cohort }
  let(:other_cohort) { create(:cohort, registration_starts_at: cohort.registration_starts_at.next_year) }
  let(:declaration_type) { "started" }
  let!(:milestone) { create(:milestone, course_cohort:, declaration_type:) }
  let(:statement_month) { 5 }
  let(:new_statement_month) { 12 }
  let(:statement_date) { Date.new(cohort.start_year, new_statement_month, 1) }
  let(:acceptance_window_start_date) { Date.new(cohort.start_year, 2, 1) }
  let(:acceptance_window_end_date) { Date.new(cohort.start_year, 2, 28) }
  let(:payment_amount) { BigDecimal("456.78") }

  context "when the statement date is missing" do
    let(:statement_date) { nil }

    it do
      expect(subject.errors).not_to be_blank
      expect(subject.errors[:statement_date]).to include("Please choose a statement date")
    end
  end

  context "when milestone is valid" do
    it "updates the milestone attributes" do
      expect(milestone.reload).to have_attributes(
        acceptance_window_start_date:,
        acceptance_window_end_date:,
        payment_amount:,
        statement_date:,
      )
    end

    it "replaces milestone statements with those for the new statement date" do
      expect(MilestoneStatement.count).to eq(LeadProvider.count)

      LeadProvider.find_each do |lead_provider|
        statement = lead_provider.statements.find_by(month: new_statement_month, year: cohort.start_year, cohort:)
        expect(MilestoneStatement.exists?(milestone:, statement:)).to be true
      end
    end
  end
end
