require "rails_helper"
require "swagger_helper"

RSpec.describe "Delivery Partners endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/delivery-partners",
                  "Delivery Partners",
                  "Delivery Partners",
                  "#/components/schemas/ListDeliveryPartnersFilter",
                  "#/components/schemas/DeliveryPartnersResponse",
                  false,
                  "#/components/schemas/DeliveryPartnersSortingOptions"
end
