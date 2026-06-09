require "rails_helper"

RSpec.describe Questionnaires::WorkSetting, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:work_setting) }
    it { is_expected.to validate_inclusion_of(:work_setting).in_array(Institution::ALL_SETTINGS) }
  end

  describe "previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq :teacher_catchment }
  end

  describe "next_step" do
    subject { described_class.new(work_setting:, wizard:).next_step }

    let(:wizard) { RegistrationWizard.new(current_step: :work_setting, store:, request: nil, current_user: build_stubbed(:user)) }
    let(:store) do
      { "teacher_catchment" => "england" }
    end

    context "with a state-funded institution" do
      let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }

      it { is_expected.to eq :choose_school }
    end

    context "with a private institution" do
      let(:work_setting) { Institution::PRIVATE_INSTITUTION }

      it { is_expected.to eq :ineligible_for_funding }
    end

    context "with another setting" do
      let(:work_setting) { Institution::OTHER }

      it { is_expected.to eq :ineligible_for_funding }
    end

    context "when not in catchment" do
      let(:store) do
        { "teacher_catchment" => "another" }
      end
      let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }

      it { is_expected.to eq :choose_school }
    end
  end

  describe "#after_save" do
    subject(:form) { described_class.new(wizard:) }

    let(:wizard) { RegistrationWizard.new(current_step: :work_setting, store:, request: nil, current_user: build_stubbed(:user)) }
    let(:store) do
      {
        "funding" => "school",
        "institution_id" => "123",
        "teacher_catchment" => "england",
      }
    end

    it "deletes funding from the wizard store" do
      expect { form.after_save }.to change { store.key?("funding") }.from(true).to(false)
    end

    it "deletes institution_id from the wizard store" do
      expect { form.after_save }.to change { store.key?("institution_id") }.from(true).to(false)
    end

    it "leaves other answers in the wizard store" do
      form.after_save
      expect(store["teacher_catchment"]).to eq("england")
    end
  end
end
