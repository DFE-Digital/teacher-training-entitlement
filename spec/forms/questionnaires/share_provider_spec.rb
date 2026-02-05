require "rails_helper"

RSpec.describe Questionnaires::ShareProvider, type: :model do
  subject(:model) { described_class.new }

  describe "validations" do
    it { is_expected.to validate_acceptance_of(:can_share_choices) }
  end

  describe "#next_step" do
    subject(:next_step) { model.next_step }

    it { is_expected.to be :check_answers }
  end

  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    let(:wizard) do
      RegistrationWizard.new(
        current_step: :share_provider,
        store:,
        request: nil,
        current_user: build_stubbed(:user),
      )
    end

    context "when user has selected a funding option (ineligible flow)" do
      let(:store) { { "funding" => "self" } }

      it { is_expected.to eq(:funding_your_course) }
    end

    context "when user has not selected a funding option (eligible flow)" do
      let(:store) { {} }

      it { is_expected.to eq(:possible_funding) }
    end
  end
end
