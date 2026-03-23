require "rails_helper"
require "swagger_helper"

RSpec.describe "Applications endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"
  let(:course) { create(:course, :tte_early_years) }
  let(:schedule) { create(:schedule, :tte_reception_autumn) }
  let(:course_cohort) { create(:course_cohort, course:, schedule:) }
  let(:application) { create(:application, lead_provider:, course_cohort:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/applications",
                  "Applications",
                  "applications",
                  "#/components/schemas/ListApplicationsFilter",
                  "#/components/schemas/ApplicationsResponse",
                  true

  it_behaves_like "an API show endpoint documentation",
                  "/api/v1/applications/{id}",
                  "Applications",
                  "application",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end

  describe "accept/reject/change-funded-place actions" do
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/ApplicationResponse", version: :v1)
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/applications/{id}/accept",
                    "Applications",
                    "Accept an application",
                    "The application being accepted",
                    "#/components/schemas/ApplicationResponse",
                    "#/components/schemas/ApplicationAcceptRequest" do
      let(:resource) { application }
      let(:type) { "application" }
      let(:attributes) { { funded_place: false } }
      let(:invalid_attributes) { { funded_place: nil } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:status] = "accepted"
          example[:data][:attributes][:funded_place] = true
        end
      end
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/applications/{id}/reject",
                    "Applications",
                    "Reject an application",
                    "The application being rejected",
                    "#/components/schemas/ApplicationResponse" do
      let(:resource) { application }
      let(:type) { "application-reject" }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:status] = "rejected"
        end
      end
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/applications/{id}/change-funded-place",
                    "Applications",
                    "Change funded place value of an application",
                    "The application after changing the funded place",
                    "#/components/schemas/ApplicationResponse",
                    "#/components/schemas/ApplicationChangeFundedPlaceRequest" do
      let(:application) { create(:application, :accepted, :eligible_for_funding, lead_provider:, course_cohort:) }
      let(:resource) { application }
      let(:type) { "application" }
      let(:attributes) { { funded_place: true } }
      let(:invalid_attributes) { { funded_place: nil } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:status] = "accepted"
          example[:data][:attributes][:funded_place] = true
        end
      end
    end
  end
end
