require "rails_helper"

RSpec.describe Questionnaires::PossibleFunding do
  let(:store) { {} }

  let(:wizard) do
    RegistrationWizard.new(
      current_step: :possible_funding,
      store:,
      request: nil,
      current_user: build_stubbed(:user),
    )
  end

  describe "#next_step" do
    subject { described_class.new.next_step }

    it { is_expected.to eq :share_provider }
  end

  describe "#previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq :choose_school }
  end

  describe "#course" do
    let(:course) { build_stubbed(:course, :tte_early_years) }
    let(:store) { { "course_identifier" => course.identifier } }
    let(:request) { nil }

    before do
      subject.wizard = wizard
    end

    it "returns the course undertaken" do
      expect(subject.course).to eql(course)
    end
  end
end
