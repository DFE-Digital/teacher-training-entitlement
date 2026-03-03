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
    it_behaves_like "an API index endpoint with filter by training_status"
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

  describe "PUT /api/v1/participants/:ecf_id/resume" do
    let(:training_status) { "deferred" }
    let(:application) { create(:application, :accepted, training_status:, lead_provider: current_lead_provider) }
    let(:resource_id) { application.user.ecf_id }
    let(:params) { { data: { attributes: { course_identifier: application.course.identifier, lead_provider: current_lead_provider } } } }

    before do
      api_put(resume_api_v1_participant_path(ecf_id: application.user.ecf_id), params:)
    end

    context "when the participant can be resumed" do
      it_behaves_like "a successful api call"
    end

    context "when the participant cannot be resumed" do
      let(:training_status) { "active" }
      let(:expected_response) do
        {
          "errors" => [{ "title" => "base", "detail" => "The participant is already active" }],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/participants/:ecf_id/defer" do
    let(:training_status) { "active" }
    let(:application) { create(:application, :accepted, :with_declaration, training_status:, lead_provider: current_lead_provider) }
    let(:resource_id) { application.user.ecf_id }
    let(:params) { { data: { attributes: { reason: "career-break", course_identifier: application.course.identifier, lead_provider: current_lead_provider } } } }

    before do
      api_put(defer_api_v1_participant_path(ecf_id: application.user.ecf_id), params:)
    end

    context "when the participant can be deferred" do
      it_behaves_like "a successful api call"
    end

    context "when the participant cannot be deferred" do
      let(:training_status) { "deferred" }
      let(:expected_response) do
        {
          "errors" => [{ "title" => "base", "detail" => "The participant is already deferred" }],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/participants/:ecf_id/withdraw" do
    let(:training_status) { "active" }
    let(:application) { create(:application, :accepted, :with_declaration, training_status:, lead_provider: current_lead_provider) }
    let(:resource_id) { application.user.ecf_id }
    let(:params) { { data: { attributes: { reason: "insufficient-capacity", course_identifier: application.course.identifier, lead_provider: current_lead_provider } } } }

    before do
      api_put(withdraw_api_v1_participant_path(ecf_id: application.user.ecf_id), params:)
    end

    context "when the participant can be withdrawn" do
      it_behaves_like "a successful api call"
    end

    context "when the participant cannot be withdrawn" do
      let(:training_status) { "withdrawn" }
      let(:expected_response) do
        {
          "errors" => [{ "title" => "base", "detail" => "The participant is already withdrawn" }],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/participants/:ecf_id/change-schedule" do
    let(:application) { create(:application, :with_declaration, lead_provider: current_lead_provider) }
    let(:schedule_identifier) { application.schedule.identifier }
    let(:course_identifier) { application.course.identifier }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::ChangeSchedule }
    let(:action) { :change_schedule }
    let(:attributes) { { schedule_identifier:, course_identifier:, lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      change_schedule_api_v1_participant_path(id)
    end

    it_behaves_like "an API update endpoint"
  end
end
