require "rails_helper"

RSpec.describe DeliveryPartnerships::Update do
  subject(:result) { described_class.new(course:, lead_provider:, selected_ids:).call }

  let(:course) { create(:course) }
  let!(:partnership_b) { create(:delivery_partnership, course:, lead_provider:, delivery_partner: partner_b) }
  let(:selected_ids) { [partner_a.id] }
  let(:lead_provider) { create(:lead_provider) }
  let(:partner_a) { create(:delivery_partner, name: "A") }
  let(:partner_b) { create(:delivery_partner, name: "B") }
  let(:partner_c) { create(:delivery_partner, name: "C") }

  before { create(:delivery_partnership, course:, lead_provider:, delivery_partner: partner_a) }

  it "archives removed partnerships without deleting rows" do
    expect { result }.not_to change(DeliveryPartnership, :count)
    expect(partnership_b.reload).to be_archived
  end

  it "reports added and removed partners" do
    expect(result.removed).to eq([partner_b])
    expect(result.added).to be_empty
  end

  context "when adding a partner without a partnership" do
    let(:selected_ids) { [partner_a.id, partner_b.id, partner_c.id] }

    it "creates the partnership" do
      expect { result }.to change(DeliveryPartnership.active, :count).by(1)
    end
  end

  context "when adding a partner with an archived partnership" do
    before { partnership_b.archive! }

    let(:selected_ids) { [partner_a.id, partner_b.id] }

    it "unarchives the existing row" do
      expect { result }.not_to change(DeliveryPartnership, :count)
      expect(partnership_b.reload).not_to be_archived
    end
  end

  context "when nothing is selected" do
    let(:selected_ids) { [] }

    it "fails and changes nothing" do
      expect(result).not_to be_success
      expect(result.error).to eq("Select at least one delivery partner")
      expect(DeliveryPartnership.active.count).to eq(2)
    end
  end

  context "when only unknown ids are selected" do
    let(:selected_ids) { [0] }

    it "fails and changes nothing" do
      expect(result).not_to be_success
      expect(DeliveryPartnership.active.count).to eq(2)
    end
  end

  context "when a change fails part way" do
    let(:selected_ids) { [partner_a.id, partner_c.id] }

    before do
      allow(DeliveryPartnership).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
    end

    it "rolls everything back" do
      expect(result).not_to be_success
      expect(partnership_b.reload).not_to be_archived
    end
  end

  context "with partnerships for other lead providers" do
    let!(:other) { create(:delivery_partnership, course:, delivery_partner: partner_b) }

    it "leaves them untouched" do
      result
      expect(other.reload).not_to be_archived
    end
  end

  it "records versions", :versioning do
    expect { result }.to change { PaperTrail::Version.where(item_type: "DeliveryPartnership").count }.by(1)
  end

  it "locks the course and lead provider partnerships in id order" do
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?("FOR UPDATE") }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { result }

    expect(queries.size).to eq(1)
    expect(queries.first).to include('"delivery_partnerships"."lead_provider_id"', "ORDER BY")
  end
end
