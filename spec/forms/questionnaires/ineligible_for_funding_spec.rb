require "rails_helper"

RSpec.describe Questionnaires::IneligibleForFunding, type: :model do
  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    let(:wizard) do
      RegistrationWizard.new(
        current_step: :ineligible_for_funding,
        store:,
        request: nil,
        current_teacher: build_stubbed(:teacher),
      )
    end

    context "when teacher selected a state-funded institution" do
      let(:store) { { "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE, "work_setting" => Institution::STATE_FUNDED_INSTITUTION } }

      it { is_expected.to eq(:choose_school) }
    end

    context "when teacher selected a private institution" do
      let(:store) { { "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE, "work_setting" => Institution::PRIVATE_INSTITUTION } }

      it { is_expected.to eq(:work_setting) }
    end

    context "when teacher selected another work setting" do
      let(:store) { { "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE, "work_setting" => Institution::OTHER } }

      it { is_expected.to eq(:work_setting) }
    end

    context "when teacher is not in England" do
      let(:store) { { "teacher_catchment" => "another" } }

      it { is_expected.to eq(:teacher_catchment) }
    end
  end
end
