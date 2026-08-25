require "rails_helper"
require "swagger_helper"

RSpec.describe "Course cohort endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/schedules",
                  "Schedules",
                  "Lead providers available schedule details",
                  "#/components/schemas/ListSchedulesFilter",
                  "#/components/schemas/SchedulesResponse",
                  false
end
