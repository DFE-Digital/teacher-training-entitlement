require "rails_helper"

RSpec.describe "Delivery Partner endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { DeliveryPartnerships::Query }
  let(:serializer) { API::DeliveryPartnerSerializer }
  let(:serializer_version) { :v1 }
  let(:serializer_lead_provider) { current_lead_provider }
  let(:serializer_cohort_start_years_by_delivery_partner) { current_lead_provider.cohort_start_years_by_delivery_partner }

  describe "GET /api/v1/delivery_partners/:id" do
    let(:resource) { create(:delivery_partner, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v1_delivery_partner_path(id)
    end

    it_behaves_like "an API show endpoint"

    context "when the partner is on a course with cohorts for the lead provider" do
      let(:cohort_2024) { create(:cohort, registration_starts_at: Date.new(2024, 9, 1)) }
      let(:course) { create(:course) }
      let(:resource) { create(:delivery_partner, lead_providers: { course => current_lead_provider }) }

      before { create(:course_cohort, cohort: cohort_2024, course:, lead_provider: current_lead_provider) }

      it "returns the partner with the derived cohort" do
        api_get(path(resource_id))

        expect(parsed_response["data"]["attributes"]["cohort"]).to eq([2024])
      end
    end

    context "when the partner belongs to another lead provider", :exceptions_app do
      let(:other_resource) { create(:delivery_partner, lead_providers: { create(:course) => create(:lead_provider) }) }

      it "returns not found" do
        api_get(path(other_resource.ecf_id))

        expect(response.status).to eq(404)
      end
    end
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
      let(:cohort_2023) { create(:cohort, registration_starts_at: Date.new(2023, 9, 1)) }
      let(:cohort_2024) { create(:cohort, registration_starts_at: Date.new(2024, 9, 1)) }
      let(:course_cohort_2023) { create(:course_cohort, cohort: cohort_2023, course: create(:course), lead_provider: current_lead_provider) }
      let(:course_cohort_2024) { create(:course_cohort, cohort: cohort_2024, course: create(:course), lead_provider: current_lead_provider) }
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

      it "returns an empty list when the cohort filter is invalid" do
        api_get(path, params: { filter: { cohort: "abc" } })

        expect(response.status).to eq(200)
        expect(parsed_response["data"]).to be_empty
      end
    end

    context "when filtering by course" do
      let(:cohort_2024) { create(:cohort, registration_starts_at: Date.new(2024, 9, 1)) }
      let(:cohort_2025) { create(:cohort, registration_starts_at: Date.new(2025, 9, 1)) }
      let(:course) { create(:course) }
      let(:other_course) { create(:course) }

      let!(:partner_on_course) { create(:delivery_partner, lead_providers: { course => current_lead_provider }) }
      let!(:partner_on_other_course) { create(:delivery_partner, lead_providers: { other_course => current_lead_provider }) }
      let!(:partner_on_both_courses) { create(:delivery_partner, lead_providers: { course => current_lead_provider, other_course => current_lead_provider }) }

      before do
        create(:delivery_partner, lead_providers: { course => create(:lead_provider) })
        create(:course_cohort, cohort: cohort_2024, course:, lead_provider: current_lead_provider)
        create(:course_cohort, cohort: cohort_2025, course:, lead_provider: current_lead_provider)
        create(:course_cohort, cohort: cohort_2024, course: other_course, lead_provider: current_lead_provider)
      end

      it "returns only the calling lead provider's partners on the specified course" do
        api_get(path, params: { filter: { course: course.identifier } })

        expect(response_ids).to contain_exactly(partner_on_course.ecf_id, partner_on_both_courses.ecf_id)
      end

      it "returns partners matching any of several comma-separated course identifiers, each once" do
        api_get(path, params: { filter: { course: "#{course.identifier},#{other_course.identifier}" } })

        expect(response_ids).to contain_exactly(partner_on_course.ecf_id, partner_on_other_course.ecf_id, partner_on_both_courses.ecf_id)
      end

      it "returns an empty list when the course identifier matches no course" do
        api_get(path, params: { filter: { course: "unknown-course-identifier" } })

        expect(response.status).to eq(200)
        expect(parsed_response["data"]).to be_empty
      end

      it "calls the correct query" do
        expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, course_identifier: course.identifier)).and_call_original

        api_get(path, params: { filter: { course: course.identifier } })
      end

      context "when combined with a cohort filter" do
        it "returns only partners matching both filters" do
          api_get(path, params: { filter: { course: course.identifier, cohort: "2025" } })

          expect(response_ids).to contain_exactly(partner_on_course.ecf_id, partner_on_both_courses.ecf_id)
        end

        it "returns an empty list when no partner matches both filters" do
          api_get(path, params: { filter: { course: other_course.identifier, cohort: "2025" } })

          expect(parsed_response["data"]).to be_empty
        end
      end
    end

    context "when serializing the derived cohort list" do
      let(:cohort_2023) { create(:cohort, registration_starts_at: Date.new(2023, 9, 1)) }
      let(:cohort_2024) { create(:cohort, registration_starts_at: Date.new(2024, 9, 1)) }
      let(:cohort_2025) { create(:cohort, registration_starts_at: Date.new(2025, 9, 1)) }
      let(:course) { create(:course) }
      let(:other_course) { create(:course) }

      let!(:delivery_partner) { create(:delivery_partner, lead_providers: { course => current_lead_provider, other_course => current_lead_provider }) }

      before do
        create(:course_cohort, cohort: cohort_2025, course:, lead_provider: current_lead_provider)
        create(:course_cohort, cohort: cohort_2023, course:, lead_provider: current_lead_provider)
        create(:course_cohort, cohort: cohort_2024, course: other_course, lead_provider: current_lead_provider)
        create(:course_cohort, cohort: cohort_2023, course: other_course, lead_provider: current_lead_provider)
      end

      it "returns the unique, sorted union of the lead provider's cohorts across the partner's courses" do
        api_get(path)

        partner_data = parsed_response["data"].find { |data| data["id"] == delivery_partner.ecf_id }
        expect(partner_data).to be_present
        expect(partner_data["attributes"]["cohort"]).to eq([2023, 2024, 2025])
      end

      context "when the lead provider has a course cohort provider for every cohort of the course" do
        let!(:single_course_partner) { create(:delivery_partner, lead_providers: { course => current_lead_provider }) }

        it "lists the partner once with every cohort of the course" do
          api_get(path)

          partner_data = parsed_response["data"].select { |data| data["id"] == single_course_partner.ecf_id }
          expect(partner_data.size).to eq(1)
          expect(partner_data.first["attributes"]["cohort"]).to eq([2023, 2025])
        end
      end

      context "when the lead provider has no course cohort provider for the partner's course" do
        let(:uncontracted_course) { create(:course) }
        let(:other_lead_provider) { create(:lead_provider) }
        let!(:uncontracted_partner) { create(:delivery_partner, lead_providers: { uncontracted_course => current_lead_provider }) }

        before do
          create(:course_cohort, cohort: cohort_2024, course: uncontracted_course, lead_provider: other_lead_provider)
        end

        it "includes the partner with an empty cohort in the unfiltered list" do
          api_get(path)

          partner_data = parsed_response["data"].find { |data| data["id"] == uncontracted_partner.ecf_id }
          expect(partner_data).to be_present
          expect(partner_data["attributes"]["cohort"]).to eq([])
        end

        it "includes the partner in filter[course] results" do
          api_get(path, params: { filter: { course: uncontracted_course.identifier } })

          expect(response_ids).to contain_exactly(uncontracted_partner.ecf_id)
        end

        it "excludes the partner from filter[cohort] results" do
          api_get(path, params: { filter: { cohort: "2024" } })

          expect(response_ids).not_to include(uncontracted_partner.ecf_id)
        end
      end
    end
  end
end
