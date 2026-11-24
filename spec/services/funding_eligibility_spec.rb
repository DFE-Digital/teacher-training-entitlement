require "rails_helper"

RSpec.describe FundingEligibility do
  subject(:funding_eligibility) do
    described_class.new(
      institution:,
      course:,
      query_store:,
    )
  end

  let(:current_teacher) { create(:teacher, :with_one_login_id, trn: "1234567") }
  let(:store) do
    {
      work_setting:,
      kind_of_nursery:,
      "current_teacher" => current_teacher,
    }.stringify_keys
  end

  let(:institution) { build(:institution) }
  let(:work_setting) { nil }
  let(:kind_of_nursery) { nil }
  let(:course) { build(:course, :npd_eirt) }
  let(:query_store) { RegistrationQueryStore.new(store:) }

  describe "#funding_eligibility" do
    subject { funding_eligibility.funding_eligibility }

    context "when outside England" do
      let(:institution) { build(:institution, :not_in_england) }

      it { is_expected.to eq :not_in_england }
    end

    context "when previously funded" do
      before do
        create(:application, :with_funded_place, :accepted, teacher: current_teacher, course:)
      end

      it { is_expected.to eq :previously_funded }
    end

    context "when work setting is a state funded institution" do
      let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }

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

    context "when work setting is another_setting" do
      let(:work_setting) { "another_setting" }

      it { is_expected.to eq :ineligible_setting }
    end

    context "when work setting is other" do
      let(:work_setting) { "other" }

      it { is_expected.to eq :ineligible_setting }
    end
  end

  describe "#funded?" do
    subject { funding_eligibility.funded? }

    let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }

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

    context "when teacher has an accepted application with funding" do
      before do
        create(:application, :with_funded_place, :accepted, teacher: current_teacher, course:)
      end

      it { is_expected.to be true }
    end
  end
end
