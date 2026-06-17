require "rails_helper"

RSpec.describe Questionnaires::TeacherCatchment, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:teacher_catchment) }
    it { is_expected.to validate_inclusion_of(:teacher_catchment).in_array(described_class::OPTIONS) }
  end

  context "when happy path" do
    describe "next_step" do
      subject { instance.next_step }

      let(:instance) { described_class.new(teacher_catchment: "england") }

      it { is_expected.to eq :work_setting }
    end

    describe "previous_step" do
      subject { described_class.new.previous_step }

      it { is_expected.to eq :choose_your_provider }
    end
  end

  context "when sad path" do
    describe "next_step" do
      subject { instance.next_step }

      let(:instance) { described_class.new(teacher_catchment: "another") }

      it { is_expected.to eq :ineligible_for_funding }
    end
  end
end
