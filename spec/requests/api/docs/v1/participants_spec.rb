require "rails_helper"
require "swagger_helper"

RSpec.describe "Participants endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:course) { create(:course, :tte_early_years) }
  let(:cohort) { create(:cohort, :current) }
  let(:schedule) { create(:schedule, :tte_reception_autumn, cohort:) }
  let(:user) { create(:user, :with_verified_trn) }
  let(:application) do
    create(:application,
           :accepted,
           :with_declaration,
           :eligible_for_funded_place,
           :with_participant_id_change,
           lead_provider:,
           course:,
           cohort:,
           schedule:,
           user:,
           funded_place: true)
  end
  let!(:participant) { application.user }

  before do
    statement = create(:statement, cohort:, lead_provider:)
    create(:contract, statement:, course:)
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
