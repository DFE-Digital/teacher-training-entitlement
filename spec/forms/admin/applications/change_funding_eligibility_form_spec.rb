# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::ChangeFundingEligibilityForm, type: :model do
  let(:eligible_for_funding) { false }
  let(:application) { create(:application, :accepted) }

  subject(:service) { described_class.new(application:, eligible_for_funding:) }

  before { allow(GenericMailer).to receive(:eligible_for_funding).and_call_original }

  describe "validations" do
    it { is_expected.to validate_presence_of :application }

    context "when not chnanging the flag" do
      let(:eligible_for_funding) { application.eligible_for_funding }

      it "is not valid" do
        expect(service).not_to be_valid
        expect(service.errors[:eligible_for_funding]).to include("Please choose a different funding eligibility status to continue")
      end
    end
  end
end
