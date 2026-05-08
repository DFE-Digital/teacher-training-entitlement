require "rails_helper"

RSpec.describe ApplicationEvent do
  it { is_expected.to belong_to(:application) }
  it { is_expected.to belong_to(:lead_provider).optional }
  it { is_expected.to validate_presence_of(:event) }

  describe "#set_lead_provider" do
    let(:lead_provider) { create(:lead_provider) }
    let(:application) { create(:application, lead_provider:) }

    it "sets the lead provider from the application's current lead provider before create" do
      application_event = described_class.create!(application:, event: "test_event")

      expect(application_event.lead_provider).to eq(lead_provider)
    end

    it "keeps an explicitly set lead provider" do
      explicit_lead_provider = create(:lead_provider)

      application_event = described_class.create!(
        application:,
        event: "test_event",
        lead_provider: explicit_lead_provider,
      )

      expect(application_event.lead_provider).to eq(explicit_lead_provider)
    end

    it "allows the lead provider to remain nil when the application has no current lead provider" do
      application.application_lead_providers.current.destroy_all

      application_event = described_class.create!(application:, event: "test_event")

      expect(application_event.lead_provider).to be_nil
    end
  end
end
