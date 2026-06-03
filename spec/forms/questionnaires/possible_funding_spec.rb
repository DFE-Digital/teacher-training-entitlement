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
    subject do
      form = described_class.new
      form.wizard = wizard
      form.previous_step
    end

    it { is_expected.to eq :choose_school }
  end

  describe "#course" do
    let!(:course) { create(:course, :npd_eirt) }
    let(:request) { nil }

    before do
      subject.wizard = wizard
    end

    it "returns the course undertaken" do
      expect(subject.course).to eql(course)
    end
  end

  describe "#after_save" do
    subject do
      form = described_class.new
      form.wizard = wizard
      form
    end

    let(:store) { { "funding" => "scholarship" } }

    it "clears the funding value" do
      expect { subject.after_save }.to change { wizard.store["funding"] }.from("scholarship").to(nil)
    end
  end
end
