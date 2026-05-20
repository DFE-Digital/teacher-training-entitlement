require "rails_helper"

RSpec.describe FundingEligibility do
  subject(:funding_eligibility) do
    described_class.new(
      institution:,
      course:,
      inside_catchment:,
      user: current_user,
      work_setting:,
    )
  end

  let(:current_user) { create(:user, :with_one_login_id, trn: "1234567") }
  let(:inside_catchment) { true }
  let(:institution) { nil }
  let(:work_setting) { nil }
  let(:course) { create(:course, :tte_early_years) }

  describe "#funding_eligiblity_status_code" do
    subject { funding_eligibility.funding_eligiblity_status_code }

    context "when outside England" do
      let(:inside_catchment) { false }

      it { is_expected.to eq :not_in_england }
    end

    context "when previously funded" do
      before do
        create(:application, :with_funded_place, :accepted, user: current_user, course:)
      end

      it { is_expected.to eq :previously_funded }
    end

    context "when work setting is a state-funded institution" do
      let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }
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

    context "when work setting is other" do
      let(:work_setting) { Institution::OTHER }

      it { is_expected.to eq :ineligible_setting }
    end

    context "when work setting is private institution" do
      let(:work_setting) { Institution::PRIVATE_INSTITUTION }

      it { is_expected.to eq :ineligible_setting }
    end

    context "when institution is mandatory but missing" do
      let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }

      it "raises an error" do
        expect { subject }.to raise_error(FundingEligibility::MissingMandatoryInstitution)
      end
    end
  end

  describe "#funded?" do
    subject { funding_eligibility.funded? }

    let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }
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
        create(:application, :with_funded_place, :accepted, user: current_user, course:)
      end

      it { is_expected.to be true }
    end
  end

  describe "#get_description_for_funding_status" do
    subject { funding_eligibility.get_description_for_funding_status }

    let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }
    let(:institution) { build(:school) }

    before do
      allow(institution).to receive(:eligible_establishment?).and_return(true)
    end

    it { is_expected.to eq "You're not eligible for scholarship funding as you do not work in one of the eligible settings, such as state-funded schools." }
  end
end
