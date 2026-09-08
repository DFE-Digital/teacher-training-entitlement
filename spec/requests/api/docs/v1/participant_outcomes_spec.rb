require "rails_helper"
require "swagger_helper"

RSpec.describe "Participant Outcomes endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:course_group) { CourseGroup.find_by(name: "reception") || create(:course_group, name: "reception") }
  let(:course) { create(:course, :npd_eirt) }
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }
  let(:application) do
    create(
      :application,
      course_cohort:,
      lead_provider:,
    )
  end
  let(:declaration) { create(:declaration, :completed, application:) }

  before { create(:participant_outcome, declaration:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/outcomes",
                  "Outcomes",
                  "Outcomes for all participants",
                  "#/components/schemas/ListParticipantOutcomesFilter",
                  "#/components/schemas/ParticipantOutcomesResponse"
end
