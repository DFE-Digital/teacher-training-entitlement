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

    context "when user works in a school (previously funded)" do
      let(:store) { { "teacher_catchment" => "england", "works_in_school" => "yes" } }

      it { is_expected.to eq(:choose_school) }
    end

    context "when user selected public nursery (preschool class as part of school)" do
      let(:store) { { "teacher_catchment" => "england", "kind_of_nursery" => "preschool_class_as_part_of_school" } }

      it { is_expected.to eq(:choose_school) }
    end

    context "when user selected public nursery (local authority maintained)" do
      let(:store) { { "teacher_catchment" => "england", "kind_of_nursery" => "local_authority_maintained_nursery" } }

      it { is_expected.to eq(:choose_school) }
    end

    context "when user selected private nursery" do
      let(:store) { { "teacher_catchment" => "england", "kind_of_nursery" => "private_nursery" } }

      it { is_expected.to eq(:kind_of_nursery) }
    end

    context "when user selected childminder" do
      let(:store) { { "teacher_catchment" => "england", "kind_of_nursery" => "childminder" } }

      it { is_expected.to eq(:kind_of_nursery) }
    end

    context "when user selected another early years setting" do
      let(:store) { { "teacher_catchment" => "england", "kind_of_nursery" => "another_early_years_setting" } }

      it { is_expected.to eq(:kind_of_nursery) }
    end

    context "when user selected other work setting" do
      let(:store) { { "teacher_catchment" => "england", "work_setting" => "other" } }

      it { is_expected.to eq(:work_setting) }
    end

    context "when user is not in England" do
      let(:store) { { "teacher_catchment" => "another" } }

      it { is_expected.to eq(:work_setting) }
    end
  end
end
