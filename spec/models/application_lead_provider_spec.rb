# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationLeadProvider, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to :application }
    it { is_expected.to belong_to :lead_provider }
  end

  describe "validations" do
    describe "uniqueness" do
      subject { described_class.new }

      before { create(:application_lead_provider) }

      it "lead provider must be unique for a given application" do
        expect(subject).to validate_uniqueness_of(:lead_provider_id).scoped_to(:application_id)
      end
    end
  end
end
