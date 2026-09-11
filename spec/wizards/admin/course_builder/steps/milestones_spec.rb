require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::Milestones do
  subject(:step) { described_class.new(milestone_types:) }

  let(:milestone_types) { [] }

  describe "#milestone_types" do
    it "defaults to started and completed" do
      expect(described_class.new.milestone_types).to contain_exactly(Milestone::STARTED, Milestone::COMPLETED)
    end

    it "always includes started and completed" do
      expect(step.milestone_types).to contain_exactly(Milestone::STARTED, Milestone::COMPLETED)
    end

    context "when optional milestone types are selected" do
      let(:milestone_types) { [Milestone::RETAINED_1] }

      it "keeps the optional selected milestones" do
        expect(step.milestone_types).to contain_exactly(Milestone::STARTED, Milestone::COMPLETED, Milestone::RETAINED_1)
      end
    end
  end

  describe "#required_milestone_type?" do
    it "returns true for started and completed" do
      expect(step.required_milestone_type?(Milestone::STARTED)).to be true
      expect(step.required_milestone_type?(Milestone::COMPLETED)).to be true
    end

    it "returns false for optional milestone types" do
      expect(step.required_milestone_type?(Milestone::RETAINED_1)).to be false
    end
  end
end
