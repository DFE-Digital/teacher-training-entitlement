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
  end

  context "when nothing is submitted" do
    let(:can_share_choices) { nil }

    it { is_expected.not_to be_valid }
  end
end
