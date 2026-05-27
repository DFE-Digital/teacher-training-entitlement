require "rails_helper"

RSpec.describe Questionnaires::ChooseSchool, type: :model do
  let(:current_step) { :choose_school }
  let(:store) { {} }
  let(:request) { nil }

  let(:wizard) do
    RegistrationWizard.new(current_step:, store:, request:, current_user: build_stubbed(:user))
  end

  describe "validations" do
    subject do
      described_class.new(wizard:)
    end

    describe "#institution_id" do
      it "requires institution_id to be present" do
        subject.institution_id = nil
        subject.valid?
        expect(subject.errors[:institution_id]).to include("Enter a workplace name")
      end

      it "requires institution_id to be present when empty string" do
        subject.institution_id = ""
        subject.valid?
        expect(subject.errors[:institution_id]).to include("Enter a workplace name")
      end

      it "can have institution_id as 'other'" do
        subject.institution_id = "other"
        subject.valid?
        expect(subject.errors[:institution_id]).to be_blank
      end

      it "can have institution_id as a numeric string" do
        subject.institution_id = "123456"
        subject.valid?
        expect(subject.errors[:institution_id]).to be_blank
      end

      it "cannot have institution_id as a non-numeric string" do
        subject.institution_id = "School-123456"
        subject.valid?
        expect(subject.errors[:institution_id]).to be_present
      end
    end

    it { is_expected.to validate_length_of(:institution_name).is_at_most(64) }
  end

  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    it { is_expected.to eq :work_setting }
  end

  describe "#next_step" do
    subject { described_class.new(institution_id:, wizard:).next_step }

    let(:wizard) do
      RegistrationWizard.new(current_step:, store:, request:, current_user: create(:user))
    end
    let(:course) { build_stubbed(:course, :tte_early_years) }
    let(:store) do
      {
        "course_identifier" => course.identifier.to_s,
        "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
        "teacher_catchment" => "england",
      }
    end

    context "when possible_funding" do
      let(:institution_id) { school.institution.id.to_s }
      let(:school) { create(:school) }

      it { is_expected.to eq :possible_funding }
    end

    context "when selecting other" do
      let(:institution_id) { "other" }

      it { is_expected.to eq :choose_school }
    end

    context "when school not in england" do
      let(:institution_id) { school.institution.id.to_s }
      let(:school) { create(:school, :in_wales) }

      it { is_expected.to eq :ineligible_for_funding }
    end

    context "when school has ineligible establishment type" do
      let(:institution_id) { school.institution.id.to_s }
      let(:school) { create(:school, :ineligible_establishment_type) }

      it { is_expected.to eq :ineligible_for_funding }
    end
  end
end
