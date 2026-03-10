require "rails_helper"

RSpec.describe Questionnaires::KindOfNursery, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:kind_of_nursery) }
    it { is_expected.to validate_inclusion_of(:kind_of_nursery).in_array(described_class::KIND_OF_NURSERY_OPTIONS) }
  end

  describe "#previous_step" do
    it { expect(described_class.new.previous_step).to eq(:work_setting) }
  end

  describe "#next_step" do
    subject { described_class.new(kind_of_nursery:).next_step }

    context "when public nursery option selected" do
      let(:kind_of_nursery) { "local_authority_maintained_nursery" }

      it { is_expected.to eq(:choose_school) }
    end

    context "when private nursery option selected" do
      let(:kind_of_nursery) { "private_nursery" }

      it { is_expected.to eq(:ineligible_for_funding) }
    end

    context "when childminder option selected" do
      let(:kind_of_nursery) { "childminder" }

      it { is_expected.to eq(:ineligible_for_funding) }
    end

    context "when another early years setting option selected" do
      let(:kind_of_nursery) { "another_early_years_setting" }

      it { is_expected.to eq(:ineligible_for_funding) }
    end
  end

  describe "#after_save" do
    subject { described_class.new(kind_of_nursery:, wizard:) }

    let(:store) { { "institution_id" => "123456" } }
    let(:wizard) do
      RegistrationWizard.new(current_step: :kind_of_nursery, store:, request: nil, current_user: build_stubbed(:user))
    end

    context "when private nursery selected" do
      let(:kind_of_nursery) { "private_nursery" }

      it "clears institution_id" do
        expect { subject.after_save }.to change { wizard.store["institution_id"] }.to(nil)
      end
    end

    context "when public nursery selected" do
      let(:kind_of_nursery) { "local_authority_maintained_nursery" }

      it "preserves institution_id" do
        expect { subject.after_save }.not_to(change { wizard.store["institution_id"] })
      end
    end
  end
end
