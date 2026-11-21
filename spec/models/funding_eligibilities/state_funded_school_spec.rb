require "rails_helper"

RSpec.describe FundingEligibilities::StateFundedSchool do
  subject(:rule_set) { described_class.new }

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

  describe "#evaluate" do
    subject { rule_set.evaluate(query_store, institution:) }

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
    subject { rule_set.funded?(query_store, institution:) }

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
    subject { rule_set.previously_funded?(query_store) }

    it { is_expected.to be false }

    context "when user has an accepted application with funding" do
      before do
        create(:application, :with_funded_place, :accepted, user: current_user, course:)
      end

      it { is_expected.to be true }
    end
  end

  describe "#evaluate without an institution" do
    let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }

    it "raises MissingMandatoryInstitution" do
      expect { rule_set.evaluate(query_store, institution: nil) }
        .to raise_error(described_class::MissingMandatoryInstitution)
    end
  end

  describe "#submission_attributes" do
    subject { rule_set.submission_attributes(query_store) }

    let(:institution) { create(:institution) }
    let(:work_setting) { Institution::STATE_FUNDED_INSTITUTION }
    let(:store) { super().merge("institution_id" => institution.id, "funding" => "school") }

    context "when funded" do
      before { allow_any_instance_of(Institution).to receive(:eligible_establishment?).and_return(true) }

      it { is_expected.to eq(funding_eligibility: :funded, funding_choice: nil) }
    end

    context "when not funded" do
      before { allow_any_instance_of(Institution).to receive(:eligible_establishment?).and_return(false) }

      it { is_expected.to eq(funding_eligibility: :ineligible_setting, funding_choice: "school") }
    end
  end

  describe "#key and #name" do
    it { expect(rule_set.key).to eq("state_funded_school") }
    it { expect(rule_set.name).to eq("State-funded school") }
  end
end
