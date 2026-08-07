require "rails_helper"
require "swagger_helper"

RSpec.describe "Participants endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:course) { create(:course, :npd_eirt) }
  let(:user) { create(:user) }
  let(:application_status_trait) { :accepted }
  let(:application) do
    create(:application,
           application_status_trait,
           :for_cohort_starting_on,
           :with_declaration,
           :with_accepted_event,
           :eligible_for_funded_place,
           :with_participant_id_change,
           lead_provider:,
           course:,
           user:,
           funded_place: true)
  end
  let!(:participant) { application.user }

  before do
    application.schedule.update!(identifier: "tte-reception-autumn")
  end

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participants",
                  "Participants",
                  "participants",
                  "#/components/schemas/ListParticipantsFilter",
                  "#/components/schemas/ParticipantsResponse",
                  true

  it_behaves_like "an API show endpoint documentation",
                  "/api/v1/participants/{id}",
                  "Participants",
                  "participant",
                  "#/components/schemas/ParticipantResponse" do
    let(:resource) { participant }
  end
end
