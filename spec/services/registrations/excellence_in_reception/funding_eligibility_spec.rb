require "rails_helper"

RSpec.describe Registrations::ExcellenceInReception::FundingEligibility do
  subject(:service) { described_class.new(wizard_step:) }

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
  let(:state_store) { double(read: store_data) }
  let(:wizard) { double(state_store:, current_user: user) }
  let(:wizard_step) { double(wizard:) }

  describe "#call" do
    before do
      allow(state_store).to receive(:write) { |values| store_data.merge!(values) }
      allow(state_store).to receive(:[]) { |key| store_data[key.to_s] }
      service.call
    end

    context "when the applicant is outside England" do
      let(:teacher_catchment) { Institution::OTHER }

      it "stores the not in England result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => Registrations::FundingEligibilityConstants::NOT_IN_ENGLAND)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end

    context "when the applicant was previously funded" do
      before do
        create(:application, :accepted, :eligible_for_funding, user:, course: Course.reception)
      end

      it "stores the previously funded result" do
        service.call
        expect(state_store["funding_eligibility_result"]).to eq(Registrations::FundingEligibilityConstants::PREVIOUSLY_FUNDED)
      end
    end

    context "when there is no selected institution" do
      let(:institution_id) { nil }

      it "stores the ineligible result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end

    context "when the selected institution is eligible" do
      it "stores the funded result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => Registrations::FundingEligibilityConstants::FUNDED)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end

    context "when the selected institution is ineligible" do
      let(:institution) { create(:school, :ineligible).institution }

      it "stores the ineligible result code without storing display text" do
        expect(state_store.read).to include("funding_eligibility_result" => Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING)
        expect(state_store.read).not_to have_key("funding_eligibility_result_text")
      end
    end
  end
end
