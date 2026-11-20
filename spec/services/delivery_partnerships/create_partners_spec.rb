require "rails_helper"

RSpec.describe DeliveryPartnerships::CreatePartners do
  subject(:result) { described_class.new(course:, lead_provider:, names:).call }

  let(:course) { create(:course) }
  let(:lead_provider) { create(:lead_provider) }
  let(:names) { ["  New One ", "", "New Two"] }

  it "creates trimmed partners with active partnerships" do
    expect { result }.to change(DeliveryPartner, :count).by(2).and change(DeliveryPartnership.active, :count).by(2)
    expect(DeliveryPartner.pluck(:name)).to contain_exactly("New One", "New Two")
  end

  it "generates an ecf_id" do
    result
    expect(DeliveryPartner.pluck(:ecf_id)).to all(be_present)
  end

  context "when all names are blank" do
    let(:names) { ["", " "] }

    it "returns a base error" do
      expect(result.errors).to eq(base: "Enter a delivery partner name")
    end
  end

  context "when a name matches an existing partner case-insensitively" do
    before { create(:delivery_partner, name: "new one") }

    it "errors on that input and saves nothing" do
      expect { result }.not_to change(DeliveryPartner, :count)
      expect(result.errors.keys).to eq([0])
    end
  end

  context "when two names are the same case-insensitively" do
    let(:names) { ["Same", "same "] }

    it "errors on the duplicate and saves nothing" do
      expect { result }.not_to change(DeliveryPartner, :count)
      expect(result.errors.keys).to eq([1])
    end
  end

  context "when saving fails part way" do
    before do
      allow(DeliveryPartnership).to receive(:create!).and_call_original
      allow(DeliveryPartnership).to receive(:create!).with(hash_including(delivery_partner: have_attributes(name: "New Two"))).and_raise(ActiveRecord::RecordNotUnique)
    end

    it "rolls everything back" do
      expect { result }.not_to change(DeliveryPartner, :count)
      expect(result).not_to be_success
    end
  end
end
