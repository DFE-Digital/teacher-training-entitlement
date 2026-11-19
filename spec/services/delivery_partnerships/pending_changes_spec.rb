require "rails_helper"

RSpec.describe DeliveryPartnerships::PendingChanges do
  let(:course) { create(:course) }
  let(:lead_provider) { create(:lead_provider) }
  let(:active) { create(:delivery_partner, name: "Active") }
  let(:other) { create(:delivery_partner, name: "Other") }

  before { create(:delivery_partnership, course:, lead_provider:, delivery_partner: active) }

  it "lists additions and removals" do
    result = described_class.new(course:, lead_provider:, selected_ids: [other.id.to_s]).call

    expect(result.added).to eq([other])
    expect(result.removed).to eq([active])
  end

  it "reports no changes for the current selection" do
    expect(described_class.new(course:, lead_provider:, selected_ids: ["", active.id]).call).not_to be_any
  end
end
