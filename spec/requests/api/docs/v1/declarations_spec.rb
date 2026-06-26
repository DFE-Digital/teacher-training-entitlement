require "rails_helper"
require "swagger_helper"

RSpec.describe "Declarations endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/declarations",
                  "Declarations",
                  "List declarations",
                  "#/components/schemas/ListDeclarationsFilter",
                  "#/components/schemas/DeclarationsResponse"

  describe "single declarations" do
    let(:lead_provider) { create(:lead_provider) }
    let(:type) { "declaration" }
    let(:application) { create(:application, :started, :with_declaration, lead_provider:) }
    let(:resource) { application.declarations.first }
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/DeclarationResponse", version: :v1)
    end

    it_behaves_like "an API show endpoint documentation",
                    "/api/v1/declarations/{id}",
                    "Declarations",
                    "View a declarations",
                    "#/components/schemas/DeclarationResponse"

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/declarations/{id}/void",
                    "Declarations",
                    "Void a declaration",
                    "The declaration being voided",
                    "#/components/schemas/DeclarationResponse" do
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:state] = "voided"
          example[:data][:attributes][:has_passed] = nil
          example[:data][:attributes][:clawback_statement_id] = nil
        end
      end
    end

    describe "change delivery partner" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/declarations/{id}/change-delivery-partner",
                      "Declarations",
                      "Change declaration delivery partner",
                      "The declaration delivery partner is going to be changed",
                      "#/components/schemas/DeclarationResponse",
                      "#/components/schemas/DeclarationChangeDeliveryPartnerRequest" do
      end
      let(:lead_provider) { create(:lead_provider) }
      let(:course) { create(:course, :npd_eirt) }
      let(:cohort) { create(:cohort, :current, course:) }
      let(:application) { create(:application, :accepted, course:, cohort:) }
      let(:delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:new_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:new_secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:delivery_partner_id) { new_delivery_partner.ecf_id }
      let(:secondary_delivery_partner_id) { new_secondary_delivery_partner.ecf_id }

      let(:resource) { create(:declaration, lead_provider: lead_provider, cohort:, application:) }
      let(:resource_id) { resource.ecf_id }

      let(:service_args) { { declaration: resource, delivery_partner_id:, secondary_delivery_partner_id: } }

      let(:invalid_attributes) do
        {
          delivery_partner_id: "foo",
        }
      end

      let(:attributes) do
        {
          delivery_partner_id:,
          secondary_delivery_partner_id:,
        }
      end
    end
  end
end
