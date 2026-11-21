require "rails_helper"

RSpec.describe Registration::Steps::ShareProvider do
  subject(:step) { described_class.new(can_share_choices:) }

  context "when the checkbox is ticked" do
    let(:can_share_choices) { "1" }

    it { is_expected.to be_valid }
  end

  context "when the checkbox is not ticked" do
    let(:can_share_choices) { "0" }

    it { is_expected.not_to be_valid }

    it "explains what to do" do
      step.valid?

      expect(step.errors[:can_share_choices]).to include("You must agree to share data with providers to continue")
    end
  end

  context "when nothing is submitted" do
    let(:can_share_choices) { nil }

    it { is_expected.not_to be_valid }
  end
end
