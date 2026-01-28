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

    describe "#institution_identifier" do
      it "requires institution_identifier to be present" do
        subject.institution_identifier = nil
        subject.valid?
        expect(subject.errors[:institution_identifier]).to include("Enter a workplace name")
      end

      it "requires institution_identifier to be present when empty string" do
        subject.institution_identifier = ""
        subject.valid?
        expect(subject.errors[:institution_identifier]).to include("Enter a workplace name")
      end

      it "can have institution_identifier as 'other'" do
        subject.institution_identifier = "other"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      it "can have institution_identifier as 'School-123456'" do
        subject.institution_identifier = "School-123456"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      # this is used for the sandbox environment
      it "can have institution_identifier as 'School-1234567'" do
        subject.institution_identifier = "School-1234567"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      it "can have institution_identifier as 'LocalAuthority-1'" do
        subject.institution_identifier = "LocalAuthority-1"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      it "cannot have institution_identifier as '1234567'" do
        subject.institution_identifier = "1234567"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_present
      end
    end

    it { is_expected.to validate_length_of(:institution_name).is_at_most(64) }
  end

  describe "#previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq :work_setting }
  end

  describe "#next_step" do
    subject { described_class.new(institution_identifier:, wizard:).next_step }

    let(:course) { build_stubbed(:course, :tte_early_years) }
    let(:store) do
      {
        "course_identifier" => course.identifier.to_s,
        "works_in_school" => "yes",
        "teacher_catchment" => "england",
      }
    end

    context "when possible_funding" do
      let(:institution_identifier) { "School-#{school.urn}" }
      let(:school) { create(:school) }

      it { is_expected.to eq :possible_funding }
    end

    context "when selecting other" do
      let(:institution_identifier) { "other" }

      it { is_expected.to eq :choose_school }
    end

    context "when school not in england" do
      let(:institution_identifier) { "School-#{school.urn}" }
      let(:school) { create(:school, :in_wales) }

      it { is_expected.to eq :ineligible_for_funding }
    end
  end
end
