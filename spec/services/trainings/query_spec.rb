require "rails_helper"

RSpec.describe Trainings::Query do
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

  it "filters by teacher_email" do
    expect(ids(teacher_email: ["nobody@example.com"])).to be_empty
  end
end
