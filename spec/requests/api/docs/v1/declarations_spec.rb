require "rails_helper"
require "swagger_helper"

RSpec.describe "Participant Declarations endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participant-declarations",
                  "Participant declarations",
                  "Participant declarations",
                  "#/components/schemas/ListParticipantDeclarationsFilter",
                  "#/components/schemas/ParticipantDeclarationsResponse"

  describe "single declarations" do
    let(:lead_provider) { create(:lead_provider) }
    let(:type) { "participant-declaration" } # check
    let(:application) { create(:application, :accepted, :with_declaration, lead_provider:) }
    let(:resource) { application.declarations.first }
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/ParticipantDeclarationResponse", version: :v1)
    end

    it_behaves_like "an API show endpoint documentation",
                    "/api/v1/participant-declarations/{id}",
                    "Participant declarations",
                    "Participant declarations",
                    "#/components/schemas/ParticipantDeclarationResponse"

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/participant-declarations/{id}/void",
                    "Participant declarations",
                    "Void a declaration",
                    "The participant declaration being voided",
                    "#/components/schemas/ParticipantDeclarationResponse" do
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
                      "/api/v1/participant-declarations/{id}/change-delivery-partner",
                      "Participant declarations",
                      "Change declaration delivery partner",
                      "The declaration delivery partner is going to be changed",
                      "#/components/schemas/ParticipantDeclarationResponse",
                      "#/components/schemas/ParticipantDeclarationChangeDeliveryPartnerRequest" do
      end
      let(:lead_provider) { create(:lead_provider) }
      let(:cohort) { create(:cohort, :current) }
      let(:delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:new_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:new_secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:delivery_partner_id) { new_delivery_partner.ecf_id }
      let(:secondary_delivery_partner_id) { new_secondary_delivery_partner.ecf_id }

      let(:resource) { create(:declaration, lead_provider: lead_provider) }
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
