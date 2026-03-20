require "rails_helper"

RSpec.describe "Application endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Applications::Query }
  let(:serializer) { API::ApplicationSerializer }
  let(:serializer_version) { :v1 }

  describe "GET /api/v1/applications/:id" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v1_application_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "GET /api/v1/applications" do
    let(:path) { api_v1_applications_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:application, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by cohort"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by participant_id"
    it_behaves_like "an API index endpoint with sorting"
  end

  describe "PUT /api/v1/applications/:ecf_id/accept" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::Accept }
    let(:action) { :accept }
    let(:attributes) { { funded_place: true } }
    let(:service_args) { { application: resource, funded_place: true } }
    let(:service_methods) { { application: resource } }

    def path(id = nil)
      accept_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v1/applications/:ecf_id/reject" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::Reject }
    let(:action) { :reject }
    let(:service_args) { { application: resource, reason_for_rejection: Application.reason_for_rejections[:rejected_by_provider] } }
    let(:service_methods) { { application: resource } }

    def path(id = nil)
      reject_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v1/applications/:ecf_id/change-funded-place" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::ChangeFundedPlace }
    let(:action) { :change }
    let(:attributes) { { funded_place: false } }
    let(:service_args) { { application: resource }.merge!(attributes) }

    def path(id = nil)
      change_funded_place_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v1/applications/:ecf_id/defer" do
    let(:application) { create(:application, :accepted, :with_declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { application.ecf_id }
    let(:params) { { data: { attributes: { reason: "career-break" } } } }

    before { api_put(defer_api_v1_application_path(ecf_id: application.ecf_id), params:) }

    context "when the application can be deferred" do
      it_behaves_like "a successful api call"
    end

    context "when the application cannot be deferred" do
      let(:application) { create(:application, :accepted, :with_declaration, training_status: "deferred", lead_provider: current_lead_provider) }
      let(:expected_response) do
        { "errors" => [{ "title" => "base", "detail" => "The participant is already deferred" }] }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/resume" do
    let(:application) { create(:application, :accepted, training_status: "deferred", lead_provider: current_lead_provider) }
    let(:resource_id) { application.ecf_id }
    let(:params) { { data: { attributes: {} } } }

    before { api_put(resume_api_v1_application_path(ecf_id: application.ecf_id), params:) }

    context "when the application can be resumed" do
      it_behaves_like "a successful api call"
    end

    context "when the application cannot be resumed" do
      let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
      let(:expected_response) do
        { "errors" => [{ "title" => "base", "detail" => "The participant is already active" }] }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/withdraw" do
    let(:application) { create(:application, :accepted, :with_declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { application.ecf_id }
    let(:params) { { data: { attributes: { reason: "personal-reason-other" } } } }

    before { api_put(withdraw_api_v1_application_path(ecf_id: application.ecf_id), params:) }

    context "when the application can be withdrawn" do
      it_behaves_like "a successful api call"
    end

    context "when the application cannot be withdrawn" do
      let(:application) { create(:application, :accepted, :with_declaration, training_status: "withdrawn", lead_provider: current_lead_provider) }
      let(:expected_response) do
        { "errors" => [{ "title" => "base", "detail" => "The participant is already withdrawn" }] }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/change-schedule" do
    let(:cohort) { create(:cohort, :current) }
    let(:course) { create(:course, :tte_early_years) }
    let(:schedule) { create(:schedule, :tte_reception_autumn, cohort:) }
    let(:new_schedule) { create(:schedule, :tte_reception_spring, cohort:) }
    let!(:course_cohort) { create(:course_cohort, course:, cohort:, schedule:) }
    let(:application) { create(:application, :accepted, course_cohort:, lead_provider: current_lead_provider) }
    let(:resource_id) { application.ecf_id }
    let(:params) { { data: { attributes: { schedule_id: new_schedule.ecf_id } } } }

    before { api_put(change_schedule_api_v1_application_path(ecf_id: application.ecf_id), params:) }

    context "when the schedule change is valid" do
      it_behaves_like "a successful api call"
    end
  end

  describe "POST /api/v1/applications/:ecf_id/declarations/started" do
    let(:cohort) { create(:cohort, :current) }
    let(:course) { create(:course, :tte_early_years) }
    let(:schedule) { create(:schedule, :tte_reception_autumn, cohort:) }
    let(:course_cohort) { create(:course_cohort, course:, cohort:, schedule:, lead_providers: [current_lead_provider]) }
    let(:application) { create(:application, :accepted, course_cohort:, lead_provider: current_lead_provider) }
    let(:declaration_date) { (schedule.training_starts_at + 1.day).rfc3339 }
    let(:delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:params) do
      { data: { attributes: { declaration_date:, delivery_partner_id: delivery_partner.ecf_id } } }
    end

    before { api_post(declaration_started_api_v1_application_path(ecf_id: application.ecf_id), params:) }

    context "when authorized" do
      it "returns 200 with the created declaration" do
        expect(response.status).to eq(200)
        expect(parsed_response["data"]["attributes"]["declaration_type"]).to eq("started")
        expect(parsed_response["data"]["attributes"]["application_id"]).to eq(application.ecf_id)
      end
    end

    context "when unauthorized" do
      before { api_post(declaration_started_api_v1_application_path(ecf_id: application.ecf_id), params:, token: "bad-token") }

      it "returns 401" do
        expect(response.status).to eq(401)
      end
    end
  end

  describe "POST /api/v1/applications/:ecf_id/declarations/completed" do
    let(:cohort) { create(:cohort, :current) }
    let(:course) { create(:course, :tte_early_years) }
    let(:schedule) { create(:schedule, :tte_reception_autumn, cohort:) }
    let(:course_cohort) { create(:course_cohort, course:, cohort:, schedule:, lead_providers: [current_lead_provider]) }
    let(:application) { create(:application, :accepted, course_cohort:, lead_provider: current_lead_provider) }
    let(:declaration_date) { (schedule.training_starts_at + 1.day).rfc3339 }
    let(:params) do
      { data: { attributes: { declaration_date:, has_passed: true } } }
    end

    before { api_post(declaration_completed_api_v1_application_path(ecf_id: application.ecf_id), params:) }

    context "when authorized" do
      it "returns 200 with the created declaration" do
        expect(response.status).to eq(200)
        expect(parsed_response["data"]["attributes"]["declaration_type"]).to eq("completed")
        expect(parsed_response["data"]["attributes"]["application_id"]).to eq(application.ecf_id)
      end
    end

    context "when unauthorized" do
      before { api_post(declaration_completed_api_v1_application_path(ecf_id: application.ecf_id), params:, token: "bad-token") }

      it "returns 401" do
        expect(response.status).to eq(401)
      end
    end
  end
end
