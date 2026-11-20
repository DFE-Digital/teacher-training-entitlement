require "rails_helper"

RSpec.describe Registrations::ExcellenceInReception::FundingEligibility do
  subject(:service) { described_class.new(router_step:) }

  let(:user) { create(:user) }
  let(:institution) { create(:institution) }
  let(:store_data) do
    {
      "teacher_catchment" => teacher_catchment,
      "institution_id" => institution_id,
    }
  end
  let(:teacher_catchment) { Institution::ENGLAND_SUBDIVISION_CODE }
  let(:institution_id) { institution.id }
  let(:session) { { registrations: store_data } }
  let(:state_store) { Registrations::StateStore.new(session:, key: :registrations) }
  let(:router_step) { instance_double(Registrations::RouterStep, state_store:, current_user: user) }

  describe "#call" do
    before { service.call }

    context "when the applicant is outside England" do
      let(:teacher_catchment) { Institution::OTHER }

      it "stores the not in England result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => described_class::NOT_IN_ENGLAND)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end

    context "when the applicant was previously funded" do
      before do
        create(:application, :accepted, :eligible_for_funding, user:, course: Course.reception)
      end

      it "stores the previously funded result" do
        service.call
        expect(state_store["funding_eligibility_result"]).to eq(described_class::PREVIOUSLY_FUNDED)
      end
    end

    context "when there is no selected institution" do
      let(:institution_id) { nil }

      it "stores the ineligible result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => described_class::INELIGIBLE_SETTING)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end

    context "when the selected institution is eligible" do
      it "stores the funded result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => described_class::FUNDED)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end

    context "when the selected institution is ineligible" do
      let(:institution) { create(:school, :ineligible).institution }

      it "stores the ineligible result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => described_class::INELIGIBLE_SETTING)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end
  end
end
