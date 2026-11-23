require "rails_helper"

RSpec.describe API::V2::Applications::Query do
  let(:lead_provider) { create(:lead_provider) }
  let!(:application) { create(:application, lead_provider:) }

  def ids(filters = {})
    described_class.new(lead_provider:, filters:).application_lead_providers.map { |alp| alp.application.id }
  end

  it "returns current assignments ordered by application id" do
    later = create(:application, lead_provider:)

    expect(ids).to eq([application.id, later.id])
  end

  it "excludes previous assignments" do
    application.change_provider!(to: create(:lead_provider))

    expect(ids).to be_empty
  end

  it "returns none for any funding_uplift filter" do
    expect(ids(funding_uplift: false)).to be_empty
  end

  it "filters by application email" do
    expect(ids(email: [application.email])).to eq([application.id])
  end

  it "returns none for an unknown email" do
    expect(ids(email: ["nobody@example.com"])).to be_empty
  end

  describe "#application_lead_provider" do
    it "finds a visible application by ecf_id" do
      expect(described_class.new(lead_provider:).application_lead_provider(ecf_id: application.ecf_id).application).to eq(application)
    end

    it "raises not found for another provider's application" do
      other = create(:application, lead_provider: create(:lead_provider))

      expect { described_class.new(lead_provider:).application_lead_provider(ecf_id: other.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
