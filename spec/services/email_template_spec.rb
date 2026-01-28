require "rails_helper"

RSpec.describe EmailTemplate do
  subject { described_class.call(data:) }

  let(:data) do
    {
      'funding_eligiblity_status_code': funding_eligiblity_status_code,
      'course_identifier': course_identifier,
      'targeted_delivery_funding_eligibility': targeted_delivery_funding_eligibility,
      'has_ofsted_urn': has_ofsted_urn,
    }
  end

  let(:funding_eligiblity_status_code) { FundingEligibility::FUNDED_ELIGIBILITY_RESULT }
  let(:targeted_delivery_funding_eligibility) { true }
  let(:course_identifier) { "tte-early-years" }
  let(:has_ofsted_urn) { "no" }

  context "when eligible for scholarship funding" do
    it "returns eligible_scholarship_funding" do
      expect(subject).to eq :eligible_scholarship_funding
    end

    context "but not targeted support funding" do
      let(:targeted_delivery_funding_eligibility) { false }

      it "returns eligible_scholarship_funding_not_tsf" do
        expect(subject).to eq :eligible_scholarship_funding_not_tsf
      end
    end
  end

  context "when not elgibible for scholarship (already funded) but yes for TSF" do
    let(:funding_eligiblity_status_code) { FundingEligibility::PREVIOUSLY_FUNDED }

    it "returns not_eligible_scholarship_funding" do
      expect(subject).to eq :not_eligible_scholarship_funding
    end
  end

  context "when not elgibible for scholarship (already funded) and no for TSF" do
    let(:funding_eligiblity_status_code) { FundingEligibility::PREVIOUSLY_FUNDED }
    let(:targeted_delivery_funding_eligibility) { false }

    it "returns already_funded_not_eligible_scholarship_funding_not_tsf" do
      expect(subject).to eq :already_funded_not_eligible_scholarship_funding_not_tsf
    end
  end

  context "when not in England" do
    let(:funding_eligiblity_status_code) { FundingEligibility::NOT_IN_ENGLAND }

    it "returns not_england_wrong_catchment" do
      expect(subject).to eq :not_england_wrong_catchment
    end
  end
end
