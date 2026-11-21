require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::CourseDetails do
  subject(:step) { described_class.new(name: "Course", course_group: "reception", funding_eligibility:) }

  let(:funding_eligibility) { "state_funded_school" }

  it { is_expected.to be_valid }

  context "when funding eligibility is blank" do
    let(:funding_eligibility) { "" }

    it "is invalid with a message" do
      step.validate

      expect(step.errors[:funding_eligibility]).to eq(["Choose a funding eligibility"])
    end
  end

  context "when funding eligibility is not in the registry" do
    let(:funding_eligibility) { "unknown" }

    it { is_expected.not_to be_valid }
  end
end
