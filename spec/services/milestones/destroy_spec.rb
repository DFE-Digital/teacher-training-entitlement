require "rails_helper"

RSpec.describe Milestones::Destroy, type: :model do
  subject(:service) { described_class.new(milestone_id: milestone.id) }

  let(:course_cohort) { create(:course_cohort) }
  let(:cohort) { course_cohort.cohort }
  let(:declaration_type) { "started" }
  let!(:milestone) { create(:milestone, course_cohort:, declaration_type:) }
  let(:statement_month) { 5 }

  let(:milestone_statements) do
    LeadProvider.find_each do |lead_provider|
      statement = lead_provider.statements.with_output_fee.find_by(month: statement_month, year: cohort.start_year, cohort:)
      create(:milestone_statement, milestone:, statement:)
    end
  end

  before do
    LeadProvider.find_each do |lead_provider|
      create(:statement, lead_provider:, cohort:, year: cohort.start_year, month: statement_month, output_fee: true)
    end
    milestone_statements
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:milestone_id) }
  end

  describe "#destroy!" do
    subject(:destroy_milestone) { service.destroy! }

    it "deletes the milestone and its associated milestone statements" do
      destroy_milestone

      expect(Milestone.count).to eq 0
      expect(MilestoneStatement.count).to eq 0
    end
  end
end
