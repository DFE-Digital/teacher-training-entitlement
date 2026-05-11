require "rails_helper"

RSpec.describe FundingEligibility do
  subject(:funding_eligibility) do
    described_class.new(
      institution:,
      course:,
      inside_catchment:,
      trn: "1234567",
      teacher_auth_uid: SecureRandom.uuid,
      query_store:,
    )
  end

  let(:store) do
    {
      work_setting:,
      kind_of_nursery:,
    }.stringify_keys
  end

  let(:inside_catchment) { true }
  let(:institution) { nil }
  let(:work_setting) { nil }
  let(:kind_of_nursery) { nil }
  let(:course) { build(:course, :tte_early_years) }
  let(:query_store) { RegistrationQueryStore.new(store:) }

  describe "#funding_eligiblity_status_code" do
    subject { funding_eligibility.funding_eligiblity_status_code }

    context "when outside England" do
      let(:inside_catchment) { false }

      it { is_expected.to eq :not_in_england }
    end

    context "when previously funded" do
      before do
        user = build(:user, :with_teacher_auth_uid, uid: funding_eligibility.teacher_auth_uid)
        create(:application, :with_funded_place, :accepted, user:, course:)
      end

      it { is_expected.to eq :previously_funded }
    end

    context "when work setting is school" do
      let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }
      let(:institution) { build(:school) }

      context "when institution is an eligible establishment" do
        before do
          allow(institution).to receive(:eligible_establishment?).and_return(true)
        end

        it { is_expected.to eq :funded }
      end

      context "when institution is not an eligible establishment" do
        before do
          allow(institution).to receive(:eligible_establishment?).and_return(false)
        end

        it { is_expected.to eq :ineligible_setting }
      end
    end

    context "when work setting is academy trust" do
      let(:work_setting) { Questionnaires::WorkSetting::AN_ACADEMY_TRUST }
      let(:institution) { build(:school) }

      before do
        allow(institution).to receive(:eligible_establishment?).and_return(true)
      end

      it { is_expected.to eq :funded }
    end

    context "when work setting is 16 to 19 educational setting" do
      let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }
      let(:institution) { build(:school) }

      before do
        allow(institution).to receive(:eligible_establishment?).and_return(true)
      end

      it { is_expected.to eq :funded }
    end

    context "when work setting is early years or childcare" do
      let(:work_setting) { "early_years_or_childcare" }
      let(:institution) { build(:school) }

      before do
        allow(institution).to receive(:eligible_establishment?).and_return(true)
      end

      context "when kind of nursery is local_authority_maintained_nursery" do
        let(:kind_of_nursery) { "local_authority_maintained_nursery" }

        it { is_expected.to eq :funded }
      end

      context "when kind of nursery is preschool_class_as_part_of_school" do
        let(:kind_of_nursery) { "preschool_class_as_part_of_school" }

        it { is_expected.to eq :funded }
      end

      context "when kind of nursery is private_nursery" do
        let(:kind_of_nursery) { "private_nursery" }

        it { is_expected.to eq :ineligible_setting }
      end

      context "when kind of nursery is childminder" do
        let(:kind_of_nursery) { "childminder" }

        it { is_expected.to eq :ineligible_setting }
      end

      context "when kind of nursery is another_early_years_setting" do
        let(:kind_of_nursery) { "another_early_years_setting" }

        it { is_expected.to eq :ineligible_setting }
      end

      context "when institution has ineligible establishment type" do
        let(:kind_of_nursery) { "preschool_class_as_part_of_school" }

        before do
          allow(institution).to receive(:eligible_establishment?).and_return(false)
        end

        it { is_expected.to eq :ineligible_setting }
      end
    end

    context "when work setting is another_setting" do
      let(:work_setting) { "another_setting" }

      it { is_expected.to eq :ineligible_setting }
    end

    context "when work setting is other" do
      let(:work_setting) { "other" }

      it { is_expected.to eq :ineligible_setting }
    end

    context "when institution is mandatory but missing" do
      let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }

      it "raises an error" do
        expect { subject }.to raise_error(FundingEligibility::MissingMandatoryInstitution)
      end
    end
  end

  describe "#funded?" do
    subject { funding_eligibility.funded? }

    let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }
    let(:institution) { build(:school) }

    before do
      allow(institution).to receive(:eligible_establishment?).and_return(true)
    end

    it { is_expected.to be true }

    context "when ineligible" do
      before do
        allow(institution).to receive(:eligible_establishment?).and_return(false)
      end

      it { is_expected.to be false }
    end
  end

  describe "#previously_funded?" do
    subject { funding_eligibility.previously_funded? }

    it { is_expected.to be false }

    context "when user has an accepted application with funding" do
      before do
        user = build(:user, :with_teacher_auth_uid, uid: funding_eligibility.teacher_auth_uid)
        create(:application, :with_funded_place, :accepted, user:, course:)
      end

      it { is_expected.to be true }
    end
  end

  describe "#get_description_for_funding_status" do
    subject { funding_eligibility.get_description_for_funding_status }

    let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }
    let(:institution) { build(:school) }

    before do
      allow(institution).to receive(:eligible_establishment?).and_return(true)
    end

    it { is_expected.to eq "You’re not eligible for scholarship funding." }
  end
end
