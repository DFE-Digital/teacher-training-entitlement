require "rails_helper"

RSpec.describe Questionnaires::ChooseATteAndProvider, type: :model do
  describe "#previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq :choose_your_provider }
  end

  describe "#next_step" do
    subject { described_class.new.next_step }

    it { is_expected.to be_nil }
  end
end
