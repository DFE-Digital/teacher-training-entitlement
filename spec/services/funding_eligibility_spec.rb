require "rails_helper"

RSpec.describe FundingEligibility do
  subject(:funding_eligibility) do
    described_class.new(
      institution:,
      course:,
      query_store:,
    )
  end

  let(:current_user) { create(:user, :with_one_login_id, trn: "1234567") }
  let(:store) do
    {
      work_setting:,
      kind_of_nursery:,
      "current_user" => current_user,
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
        create(:application, :with_funded_place, :accepted, user: current_user, course:)
      end

      it { is_expected.to eq :previously_funded }
    end

    context "when work setting is a state funded institution" do
      let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }

      FundingEligibility::ELIGIBLE_ESTABLISHMENT_TYPE_CODES.each_key do |code|
        context "when a state funded institution has eligible establishment type code #{code}" do
          let(:institution) { build(:institution, institution_type: Institution::STATE_FUNDED, establishment_type_code: code) }

          it { is_expected.to eq :funded }
        end
      end

      context "when a state funded institution has an ineligible establishment type code" do
        let(:institution) { build(:institution, institution_type: Institution::STATE_FUNDED, establishment_type_code: "11") }

        it { is_expected.to eq :ineligible_setting }
      end

      context "when a state funded institution has no establishment type code" do
        let(:institution) { build(:institution, institution_type: Institution::STATE_FUNDED).tap { |i| i.establishment_type_code = nil } }

        it { is_expected.to eq :ineligible_setting }
      end

      context "when institution is a further education institution with an eligible code" do
        let(:institution) { build(:institution, institution_type: Institution::FURTHER_EDUCATION, establishment_type_code: "18") }

        it { is_expected.to eq :funded }
      end

      context "when institution is a local authority" do
        let(:institution) { build(:institution, :for_local_authority, institution_type: Institution::LOCAL_AUTHORITY) }

        it { is_expected.to eq :funded }
      end

      (Institution::INSTITUTION_TYPES - [Institution::STATE_FUNDED, Institution::FURTHER_EDUCATION, Institution::LOCAL_AUTHORITY]).each do |slug|
        context "when institution type is #{slug}" do
          let(:institution) { build(:institution, institution_type: slug, establishment_type_code: "1") }

          it { is_expected.to eq :ineligible_setting }
        end
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

    let(:institution) { build(:institution, institution_type: Institution::STATE_FUNDED, establishment_type_code: "1") }

    it { is_expected.to be true }

    context "when ineligible" do
      let(:institution) { build(:institution, institution_type: Institution::STATE_FUNDED, establishment_type_code: "11") }

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
end
