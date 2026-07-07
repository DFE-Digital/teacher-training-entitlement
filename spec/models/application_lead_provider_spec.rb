# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationLeadProvider, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to :application }
    it { is_expected.to belong_to :lead_provider }
  end

  describe "validations" do
    it "allows the same lead provider to be assigned to an application more than once" do
      application = create(:application)
      lead_provider = application.lead_provider

      application_lead_provider = build(:application_lead_provider, application:, lead_provider:)

      expect(application_lead_provider).to be_valid
    end
  end
end
