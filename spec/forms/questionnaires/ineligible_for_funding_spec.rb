require "rails_helper"

RSpec.describe Questionnaires::IneligibleForFunding, type: :model do
  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    let(:wizard) do
      RegistrationWizard.new(
        current_step: :ineligible_for_funding,
        store:,
        request: nil,
        current_user: build_stubbed(:user),
      )
    end

    context "when user selected a state-funded institution" do
      let(:store) { { "teacher_catchment" => "england", "work_setting" => Institution::STATE_FUNDED_INSTITUTION } }

      it { is_expected.to eq(:choose_school) }
    end

    context "when user selected a private institution" do
      let(:store) { { "teacher_catchment" => "england", "work_setting" => Institution::PRIVATE_INSTITUTION } }

      it { is_expected.to eq(:work_setting) }
    end

    context "when user selected another work setting" do
      let(:store) { { "teacher_catchment" => "england", "work_setting" => Institution::OTHER } }

      it { is_expected.to eq(:work_setting) }
    end

    context "when user is not in England" do
      let(:store) { { "teacher_catchment" => "another" } }

      it { is_expected.to eq(:work_setting) }
    end
  end
end
