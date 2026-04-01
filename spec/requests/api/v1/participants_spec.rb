require "rails_helper"

RSpec.describe "Participant endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Participants::Query }
  let(:serializer) { API::ParticipantSerializer }
  let(:serializer_version) { :v1 }
  let(:serializer_lead_provider) { current_lead_provider }

  describe "GET /api/v1/participants" do
    let(:path) { api_v1_participants_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:user, :with_application, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by status"
    it_behaves_like "an API index endpoint with filter by from_participant_id"
    it_behaves_like "an API index endpoint with sorting"
  end

  describe "GET /api/v1/participants/:id" do
    let(:resource) { create(:user, :with_application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v1_participant_path(id)
    end

    it_behaves_like "an API show endpoint"
    it_behaves_like "an API endpoint that checks participant_id change" do
      let(:path) { api_v1_participant_path(participant_id_change.from_participant_id) }
    end
  end
end
