require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::DeliveryPartners do
  subject(:step) { described_class.new(delivery_partners:, wizard:) }

  let(:lead_provider) { create(:lead_provider, name: "Provider One") }
  let(:other_lead_provider) { create(:lead_provider, name: "Provider Two") }
  let(:delivery_partner) { create(:delivery_partner, name: "Partner One") }

  let(:selected_providers) do
    [
      Admin::CourseBuilder::StateStore::SelectedLeadProvider.new(lead_provider:, url: nil, email: nil),
    ]
  end
  let(:state_store) { instance_double(Admin::CourseBuilder::StateStore, selected_lead_providers: selected_providers) }
  let(:wizard) { instance_double(Admin::CourseBuilder::Wizard, state_store:) }
  let(:delivery_partners) { {} }

  describe ".permitted_params" do
    it "permits delivery partners keyed by lead provider and delivery partner" do
      expect(described_class.permitted_params).to eq([{ delivery_partners: {} }])
    end
  end

  describe "#delivery_partner_selected?" do
    context "when the delivery partner is ticked" do
      let(:delivery_partners) { { lead_provider.id.to_s => { delivery_partner.id.to_s => delivery_partner.id.to_s } } }

      it "returns true" do
        expect(step).to be_delivery_partner_selected(lead_provider, delivery_partner)
      end
    end

    context "when the delivery partner is not ticked" do
      let(:delivery_partners) { { lead_provider.id.to_s => { delivery_partner.id.to_s => "0" } } }

      it "returns false" do
        expect(step).not_to be_delivery_partner_selected(lead_provider, delivery_partner)
      end
    end

    context "when the delivery partner is omitted" do
      it "returns false" do
        expect(step).not_to be_delivery_partner_selected(lead_provider, delivery_partner)
      end
    end
  end

  describe "#normalize" do
    context "when a lead provider's partners are submitted as an array" do
      let(:delivery_partners) { { lead_provider.id.to_s => [delivery_partner.id.to_s] } }

      it "treats it as no partners rather than raising" do
        expect(step.delivery_partners).to eq({ lead_provider.id.to_s => {} })
        expect { step.valid? }.not_to raise_error
        expect(step).not_to be_valid
      end
    end

    context "when a lead provider's partners are submitted as a string" do
      let(:delivery_partners) { { lead_provider.id.to_s => delivery_partner.id.to_s } }

      it "treats it as no partners rather than raising" do
        expect(step.delivery_partners).to eq({ lead_provider.id.to_s => {} })
        expect { step.valid? }.not_to raise_error
        expect(step).not_to be_valid
      end
    end

    context "when the top-level value is not a hash" do
      let(:delivery_partners) { [delivery_partner.id.to_s] }

      it "treats it as no partners rather than raising" do
        expect(step.delivery_partners).to eq({})
        expect { step.valid? }.not_to raise_error
        expect(step).not_to be_valid
      end
    end
  end

  describe "validation" do
    context "when every selected lead provider has an existing delivery partner ticked" do
      let(:delivery_partners) { { lead_provider.id.to_s => { delivery_partner.id.to_s => delivery_partner.id.to_s } } }

      it { is_expected.to be_valid }
    end

    context "when a selected lead provider gives no delivery partner" do
      let(:delivery_partners) { { lead_provider.id.to_s => { delivery_partner.id.to_s => "0" } } }

      it "adds a per-lead provider error" do
        expect(step).not_to be_valid
        expect(step.error_for(lead_provider)).to eq("Select at least one delivery partner for Provider One")
      end
    end

    context "when a selected lead provider is omitted from the submission" do
      let(:delivery_partners) { {} }

      it "adds a per-lead provider error" do
        expect(step).not_to be_valid
        expect(step.error_for(lead_provider)).to eq("Select at least one delivery partner for Provider One")
      end
    end

    context "when a ticked delivery partner does not exist" do
      let(:delivery_partners) { { lead_provider.id.to_s => { "999999" => "999999" } } }

      it "rejects the submission with a clear message" do
        expect(step).not_to be_valid
        expect(step.errors[:"lead_provider_#{lead_provider.id}"]).to include("Select delivery partners from the list")
      end
    end

    context "when a ticked delivery partner alongside a valid one does not exist" do
      let(:delivery_partners) do
        {
          lead_provider.id.to_s => {
            delivery_partner.id.to_s => delivery_partner.id.to_s,
            "999999" => "999999",
          },
        }
      end

      it "rejects the submission with a clear per-lead message" do
        expect(step).not_to be_valid
        expect(step.error_for(lead_provider)).to eq("Select delivery partners from the list")
        expect(step.errors[:base]).to be_empty
      end
    end

    context "when a submitted lead provider does not exist" do
      let(:delivery_partners) do
        {
          lead_provider.id.to_s => { delivery_partner.id.to_s => delivery_partner.id.to_s },
          "999999" => { delivery_partner.id.to_s => delivery_partner.id.to_s },
        }
      end

      it "rejects the submission with a clear per-lead message" do
        expect(step).not_to be_valid
        expect(step.error_for(lead_provider)).to eq("Select delivery partners from the list")
        expect(step.errors[:base]).to be_empty
      end
    end

    context "when a submitted lead provider does not exist and no lead providers are selected" do
      let(:state_store) { instance_double(Admin::CourseBuilder::StateStore, selected_lead_providers: []) }
      let(:delivery_partners) { { "999999" => { delivery_partner.id.to_s => delivery_partner.id.to_s } } }

      it "rejects the submission with a base error" do
        expect(step).not_to be_valid
        expect(step.errors[:base]).to include("Select delivery partners from the list")
      end
    end

    context "when only some selected lead providers have a delivery partner" do
      let(:selected_providers) do
        [
          Admin::CourseBuilder::StateStore::SelectedLeadProvider.new(lead_provider:, url: nil, email: nil),
          Admin::CourseBuilder::StateStore::SelectedLeadProvider.new(lead_provider: other_lead_provider, url: nil, email: nil),
        ]
      end
      let(:delivery_partners) do
        {
          lead_provider.id.to_s => { delivery_partner.id.to_s => delivery_partner.id.to_s },
          other_lead_provider.id.to_s => { delivery_partner.id.to_s => "0" },
        }
      end

      it "adds an error only for the lead provider without a delivery partner" do
        expect(step).not_to be_valid
        expect(step.error_for(lead_provider)).to be_nil
        expect(step.error_for(other_lead_provider)).to eq("Select at least one delivery partner for Provider Two")
      end
    end

    context "when there are no selected lead providers" do
      let(:state_store) { instance_double(Admin::CourseBuilder::StateStore, selected_lead_providers: []) }

      it { is_expected.to be_valid }
    end
  end
end
