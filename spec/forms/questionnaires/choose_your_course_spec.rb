require "rails_helper"

RSpec.describe Questionnaires::ChooseYourCourse, type: :model do
  describe "next_step" do
    subject { described_class.new.next_step }

    it { is_expected.to eq(:choose_your_provider) }
  end

  describe "previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq(:course_start_date) }
  end
end
