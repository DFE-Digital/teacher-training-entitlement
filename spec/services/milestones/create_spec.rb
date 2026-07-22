require "rails_helper"

RSpec.describe Milestones::Create, type: :model do
  subject(:service) do
    described_class.new(
      course_cohort:,
      declaration_type:,
      statement_date:,
      acceptance_window_start_date:,
      acceptance_window_end_date:,
      payment_amount:,
    )
  end

  let(:lead_provider) { LeadProvider.last }
  let(:course_cohort) { create(:course_cohort) }
  let(:cohort) { course_cohort.cohort }
  let(:other_cohort) { create(:cohort, registration_starts_at: cohort.registration_starts_at.next_year) }
  let!(:cohort_statement) { create(:statement, lead_provider:, cohort:, year: cohort.start_year, month: statement_month, output_fee: true) }
  let!(:other_cohort_statement) { create(:statement, lead_provider:, cohort: other_cohort, year: cohort.start_year, month: statement_month, output_fee: true) }
  let(:declaration_type) { "started" }
  let(:statement_month) { 5 }
  let(:statement_date) { Date.new(cohort.start_year, statement_month, 1) }
  let(:acceptance_window_start_date) { Date.new(cohort.start_year, 1, 1) }
  let(:acceptance_window_end_date) { Date.new(cohort.start_year, 1, 31) }
  let(:payment_amount) { BigDecimal("123.45") }

  before do
    service.call
  end

  context "when the milestone attributes are invalid" do
    let(:declaration_type) { nil }

    it do
      expect(subject.errors).not_to be_blank
      expect(subject.errors[:declaration_type]).to be_present
    end
  end

  context "when the statement date is missing" do
    let(:statement_date) { nil }

    it "is invalid" do
      expect(subject.errors).not_to be_blank
      expect(subject.errors[:statement_date]).to include("Please choose a statement date")
    end
  end

  describe "#when milestone params are valid" do
    it "creates a milestone with the given attributes" do
      expect(Milestone.count).to eq(1)
      expect(Milestone.last).to have_attributes(
        course_cohort:,
        declaration_type:,
        acceptance_window_start_date:,
        acceptance_window_end_date:,
        payment_amount:,
        statement_date:,
      )
    end

    it "creates milestone statements for the lead provider for the given statement date" do
      expect(Milestone.count).to eq(1)
      expect(MilestoneStatement.exists?(milestone: Milestone.last, statement: cohort_statement)).to be true
    end

    context "when there aren't statements for the course cohort's cohort for all lead providers" do
      it "does not create milestone statements for the other cohorts" do
        expect(Milestone.count).to eq(1)
        expect(MilestoneStatement.exists?(milestone: Milestone.last, statement: other_cohort_statement)).to be false
      end
    end
  end
end
