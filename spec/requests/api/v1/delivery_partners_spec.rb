require "rails_helper"

RSpec.describe "Delivery Partner endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { DeliveryPartners::Query }
  let(:serializer) { API::DeliveryPartnerSerializer }
  let(:serializer_version) { :v1 }
  let(:serializer_lead_provider) { current_lead_provider }

  describe "GET /api/v1/delivery_partners/:id" do
    let(:resource) { create(:delivery_partner, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v1_delivery_partner_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "GET /api/v1/delivery_partners" do
    let(:path) { api_v1_delivery_partners_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:delivery_partner, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with sorting", %w[name]

    context "when filtering by cohort" do
      let(:cohort_2023) { create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) }
      let(:cohort_2024) { create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) }
      let(:course_cohort_2023) { create(:course_cohort, cohort: cohort_2023, academic_year: cohort_2023.start_year) }
      let(:course_cohort_2024) { create(:course_cohort, cohort: cohort_2024, academic_year: cohort_2024.start_year) }
      let!(:delivery_partner_2023) { create(:delivery_partner, lead_providers: { course_cohort_2023 => current_lead_provider }) }

      before { create(:delivery_partner, lead_providers: { course_cohort_2024 => current_lead_provider }) }

      it "returns delivery partners for the specified cohort" do
        api_get(path, params: { filter: { cohort: "2023" } })

        expect(parsed_response["data"].size).to eq(1)
        expect(parsed_response["data"].first["id"]).to eq(delivery_partner_2023.ecf_id)
      end

      it "calls the correct query" do
        expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, cohort_start_years: "2023")).and_call_original

        api_get(path, params: { filter: { cohort: 2023 } })
      end
    end
  end
end
