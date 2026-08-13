require "rails_helper"

RSpec.describe API::DeliveryPartnerSerializer, type: :serializer do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:other_lead_provider) { create(:lead_provider) }
  let(:course_cohort_21) { create(:course_cohort, cohort: cohort_21, academic_year: cohort_21.start_year) }
  let(:course_cohort_22) { create(:course_cohort, cohort: cohort_22, academic_year: cohort_22.start_year) }
  let(:course_cohort_23) { create(:course_cohort, cohort: cohort_23, academic_year: cohort_23.start_year) }
  let(:delivery_partner) do
    create(:delivery_partner,
           lead_providers: {
             course_cohort_21 => current_lead_provider,
             course_cohort_22 => current_lead_provider,
             course_cohort_23 => other_lead_provider,
           })
  end
  let(:cohort_21) { create :cohort, registration_starts_at: Date.new(2021, 4, 1) }
  let(:cohort_22) { create :cohort, registration_starts_at: Date.new(2022, 4, 1) }
  let(:cohort_23) { create :cohort, registration_starts_at: Date.new(2023, 4, 1) }

  subject(:response) { JSON.parse(described_class.render(delivery_partner)) }

  describe "core attributes" do
    it "serializes the `id`" do
      expect(response["id"]).to eq(delivery_partner.ecf_id)
    end

    it "serializes the `type`" do
      response = JSON.parse(described_class.render(delivery_partner))

      expect(response["type"]).to eq("delivery-partner")
    end
  end

  context "when serializing the v3 view" do
    describe "nested attributes" do
      subject(:attributes) { JSON.parse(described_class.render(delivery_partner, view: :v1, lead_provider: current_lead_provider))["attributes"] }

      it "serializes the `name`" do
        expect(attributes["name"]).to eq(delivery_partner.name)
      end

      it "serializes the cohorts" do
        expect(attributes["cohort"]).to eq([cohort_21.start_year, cohort_22.start_year])
      end

      it "serializes the `created_at`" do
        expect(attributes["created_at"]).to eq(delivery_partner.created_at.rfc3339)
      end

      it "serializes the `updated_at`" do
        expect(attributes["updated_at"]).to eq(delivery_partner.updated_at.rfc3339)
      end
    end
  end
end
