require "rails_helper"
require "swagger_helper"

RSpec.describe "Participant Outcomes endpoint", :npq, openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:course) { create(:course, :npd_eirt) }
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }
  let(:application) do
    create(
      :application,
      :accepted,
      course_cohort:,
      lead_provider:,
    )
  end
  let(:participant) { application.user }
  let(:declaration) { create(:declaration, :completed, application:) }

  before { create(:participant_outcome, declaration:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participants/{id}/outcomes",
                  "Participant Outcomes",
                  "Outcomes for a single participant",
                  nil,
                  "#/components/schemas/ParticipantOutcomesResponse" do
    let(:resource) { participant }
  end

  it_behaves_like "an API create on resource endpoint documentation",
                  "/api/v1/participants/{id}/outcomes",
                  "Participant Outcomes",
                  "Submit a Outcome for a single participant",
                  "The details of an Outcome",
                  "#/components/schemas/ParticipantOutcomeResponse",
                  "#/components/schemas/ParticipantOutcomeCreateRequest" do
    let(:resource) { participant }
    let(:type) { "outcome-confirmation" }
    let(:attributes) do
      {
        course_identifier: course.identifier,
        state: "passed",
        completion_date: "2021-05-31",
      }
    end
    let(:invalid_attributes) do
      {
        course_identifier: course.identifier,
        state: nil,
        completion_date: "2021-05-31",
      }
    end
  end
end
