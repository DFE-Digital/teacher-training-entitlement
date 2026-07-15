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

    context "when an application changed provider" do
      include_context "with application which changed provider"

      describe "when viewing as a provider with previous assignments" do
        it "can see the application with a reassigned status" do
          api_get(api_v1_application_path(application.ecf_id), lead_provider: old_lead_provider)

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["data"]["attributes"]["status"]).to eq(Application::REASSIGNED)
        end
      end

      describe "when viewing as a provider with previous and current assignments" do
        it "can see the application with a pending status" do
          api_get(api_v1_application_path(application.ecf_id), lead_provider: current_lead_provider)

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["data"]["attributes"]["status"]).to eq(Application::PENDING)
        end
      end
    end
  end

  describe "GET /api/v1/applications" do
    let(:serializer) { API::ApplicationLeadProviderSerializer }
    let(:path) { api_v1_applications_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      cohort = attrs.delete(:cohort)

      if cohort
        create(:application, :for_cohort_starting_on, **attrs, registration_starts_at: cohort.registration_starts_at).application_lead_providers.first
      else
        create(:application, **attrs).application_lead_providers.first
      end
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by cohort"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by status"
    it_behaves_like "an API index endpoint with filter by participant_id"
    it_behaves_like "an API index endpoint with sorting"

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { api_v1_applications_path }

      context "with the old provider" do
        let!(:pending_application) { create(:application, :pending, lead_provider: old_lead_provider) }

        it "can see the applications list with reassigned status" do
          api_get(path, lead_provider: old_lead_provider)
          expect(response_ids).to contain_exactly(application.ecf_id, pending_application.ecf_id)
          expect(JSON.parse(response.body)["data"].first["attributes"]["status"]).to eq(Application::REASSIGNED)
        end

        it "can filter the applications with reassigned status" do
          api_get(path, lead_provider: old_lead_provider, params: { filter: { status: Application::REASSIGNED } })

          expect(response_ids).to contain_exactly(application.ecf_id)
          expect(JSON.parse(response.body)["data"].size).to eq(1)
          expect(JSON.parse(response.body)["data"].first["attributes"]["status"]).to eq(Application::REASSIGNED)
        end

        it "filters applications with pending status correctly" do
          api_get(path, lead_provider: old_lead_provider, params: { filter: { status: Application::PENDING } })

          expect(response_ids).to contain_exactly(pending_application.ecf_id)
          expect(JSON.parse(response.body)["data"].size).to eq(1)
          expect(JSON.parse(response.body)["data"].first["attributes"]["status"]).to eq(Application::PENDING)
        end
      end

      context "with the new provider" do
        it "can see the application with pending status" do
          api_get(path, lead_provider: new_lead_provider)
          expect(response_ids).to include(application.ecf_id)
          expect(JSON.parse(response.body)["data"].first["attributes"]["status"]).to eq(Application::PENDING)
        end
      end

      context "when filtering by updated_since after the provider changes" do
        let(:application) { create(:application, :pending, updated_at: 2.days.ago) }

        it "includes the reassigned application for the old provider" do
          Applications::ChangeLeadProvider.new(application:, new_provider: new_lead_provider).call

          api_get(path, lead_provider: old_lead_provider, params: { filter: { updated_since: 1.hour.ago.iso8601 } })

          expect(response_ids).to contain_exactly(application.ecf_id)
          expect(JSON.parse(response.body)["data"].first["attributes"]["status"]).to eq(Application::REASSIGNED)
        end
      end

      context "with the a provider never assigned to the application" do
        it "cannot see the application" do
          api_get(path, lead_provider: create(:lead_provider))
          expect(response_ids).to be_blank
        end
      end
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/accept" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:application) { resource }
    let(:expected_data_id) { application.ecf_id }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::Accept }
    let(:action) { :call }
    let(:attributes) { { funded_place: true } }
    let(:service_args) { attributes.merge(application: resource) }
    let(:service_methods) { { application: resource } }

    def path(id = nil)
      accept_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"

    context "when the application can be deferred" do
      before do
        api_put(accept_api_v1_application_path(ecf_id: application.ecf_id), params: { data: { attributes: { funded_place: false } } })
      end

      it_behaves_like "a successful api call"

      it "creates a accepted event" do
        accepted_event = application.application_events.find { |e| e.event == Application::ACCEPTED }
        expect(accepted_event).not_to be_nil
        expect(accepted_event.metadata&.symbolize_keys).to be_blank
        expect(accepted_event.lead_provider).to eq(current_lead_provider)
      end
    end

    context "when an application changed provider" do
      include_context "with application which changed provider"

      let(:path) { accept_api_v1_application_path(ecf_id: application.ecf_id) }
      let(:params) { { data: { attributes: { funded_place: false } } } }

      it "the old provider cannot accept the application" do
        expect { api_put(path, lead_provider: old_lead_provider, params:) }
          .not_to(change { application.reload.status })

        expect(response).to be_forbidden
      end

      it "the current provider can accept the application" do
        api_put(path, lead_provider: current_lead_provider, params:)

        expect(response).to have_http_status(:ok)
        expect(application.reload.status).to eq(Application::ACCEPTED)
      end
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/reject" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::Reject }
    let(:action) { :call }
    let(:attributes) { { reason: "rejected-by-provider" } }
    let(:service_args) { attributes.merge(application: resource) }
    let(:service_methods) { { application: resource } }

    def path(id = nil)
      reject_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { reject_api_v1_application_path(ecf_id: application.ecf_id) }
      let(:params) { { data: { attributes: } } }

      it "the old provider cannot reject the application" do
        expect { api_put(path, lead_provider: old_lead_provider, params:) }
          .not_to(change { application.reload.status })

        expect(response).to be_forbidden
      end
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/change-funded-place" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::ChangeFundedPlace }
    let(:action) { :call }
    let(:attributes) { { funded_place: false } }
    let(:service_args) { attributes.merge(application: resource) }

    def path(id = nil)
      change_funded_place_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { change_funded_place_api_v1_application_path(ecf_id: application.ecf_id) }
      let(:params) { { data: { attributes: } } }

      it "the old provider cannot change the application" do
        expect { api_put(path, lead_provider: old_lead_provider, params:) }
          .not_to(change { application.reload.status })

        expect(response).to be_forbidden
      end
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/defer" do
    let(:expected_data_id) { application.ecf_id }
    let(:cohort) { create(:cohort, lead_provider: current_lead_provider) }
    let(:application_status_trait) { :started }
    let(:application) { create(:application, application_status_trait, :with_declaration, lead_provider: current_lead_provider, course: cohort.course) }
    let(:params) { { data: { attributes: { reason: "career-break" } } } }

    before do
      api_put(defer_api_v1_application_path(ecf_id: application.ecf_id), params:)
    end

    context "when the application can be deferred" do
      it_behaves_like "a successful api call"

      it "creates a deferred event" do
        deferred_event = application.application_events.find { |e| e.event == Application::DEFERRED }
        expect(deferred_event).not_to be_nil
        expect(deferred_event.metadata&.symbolize_keys).to eq(reason: "career-break")
        expect(deferred_event.lead_provider).to eq(current_lead_provider)
      end
    end

    context "when the application cannot be deferred" do
      let(:application_status_trait) { :deferred }
      let(:expected_response) do
        {
          "errors" => [
            { "title" => "application", "detail" => I18n.t("activemodel.errors.models.applications/defer.attributes.application.has_already_been_deferred") },
          ],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { defer_api_v1_application_path(ecf_id: application.ecf_id) }

      it "the old provider cannot defer the application" do
        expect { api_put(path, lead_provider: old_lead_provider, params:) }
          .not_to(change { application.reload.status })

        expect(response).to be_forbidden
      end
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/resume" do
    let(:expected_data_id) { application.ecf_id }
    let!(:cohort) do
      create(:cohort,
             :unique,
             ecf_id: SecureRandom.uuid,
             lead_provider: current_lead_provider)
    end
    let(:application_status_trait) { :deferred }
    let(:application) { create(:application, application_status_trait, lead_provider: current_lead_provider, cohort:) }
    let(:params) { { data: { attributes: { cohort_id: cohort.ecf_id } } } }

    before do
      api_put(resume_api_v1_application_path(ecf_id: application.ecf_id), params:)
    end

    context "when the application can be resumed" do
      it_behaves_like "a successful api call"
    end

    context "when the application cannot be resumed" do
      let(:application_status_trait) { :started }
      let(:expected_response) do
        {
          "errors" => [
            { "title" => "base", "detail" => I18n.t("activemodel.errors.models.applications/resume.attributes.base.application_status") },
          ],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { resume_api_v1_application_path(ecf_id: application.ecf_id) }

      it "the old provider cannot resume the application" do
        expect { api_put(path, lead_provider: old_lead_provider, params:) }
          .not_to(change { application.reload.status })

        expect(response).to be_forbidden
      end
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/withdraw" do
    let(:expected_data_id) { application.ecf_id }
    let!(:cohort) { create(:cohort, lead_provider: current_lead_provider) }
    let(:application_status_trait) { :started }
    let(:application) { create(:application, application_status_trait, :with_declaration, lead_provider: current_lead_provider, cohort:) }
    let(:params) { { data: { attributes: { reason: "insufficient-capacity" } } } }

    before do
      api_put(withdraw_api_v1_application_path(ecf_id: application.ecf_id), params:)
    end

    context "when the application is started" do
      let(:application_status_trait) { :started }

      it_behaves_like "a successful api call"

      it "creates a withdrawn event" do
        withdrawn_event = application.application_events.find { |e| e.event == Application::WITHDRAWN }
        expect(withdrawn_event).not_to be_nil
        expect(withdrawn_event.metadata&.symbolize_keys).to eq(reason: "insufficient-capacity")
        expect(withdrawn_event.lead_provider).to eq(current_lead_provider)
      end
    end

    context "when the application is accepted" do
      let(:application_status_trait) { :accepted }

      let(:expected_response) do
        {
          "errors" => [
            { "title" => "application", "detail" => I18n.t("activemodel.errors.models.applications/withdraw.attributes.application.not_withdrawable") },
          ],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end

    context "when the application is already withdrawn" do
      let(:application_status_trait) { :withdrawn }
      let(:expected_response) do
        {
          "errors" => [
            { "title" => "base", "detail" => I18n.t("activemodel.errors.models.applications/withdraw.attributes.base.already_withdrawn") },
          ],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { withdraw_api_v1_application_path(ecf_id: application.ecf_id) }

      it "the old provider cannot withdraw the application" do
        expect { api_put(path, lead_provider: old_lead_provider, params:) }
          .not_to(change { application.reload.status })

        expect(response).to be_forbidden
      end
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/change-schedule" do
    let(:resource) { create(:application, :accepted, cohort:, lead_provider: current_lead_provider) }
    let(:cohort) { create(:cohort, :unique, course:, lead_provider: current_lead_provider) }
    let(:course) { create(:course) }

    let(:target_cohort) do
      create(:cohort,
             :unique,
             :future_training,
             course: target_course,
             ecf_id: SecureRandom.uuid,
             lead_provider: current_lead_provider)
    end

    let(:target_course) { course }

    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::ChangeSchedule }
    let(:action) { :call }
    let(:attributes) { { cohort_id: target_cohort.ecf_id } }
    let(:service_args) { { application: resource, cohort: target_cohort } }

    def path(id = nil)
      change_schedule_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { change_schedule_api_v1_application_path(ecf_id: application.ecf_id) }
      let(:params) { { data: { attributes: } } }

      it "the old provider cannot change the application" do
        expect { api_put(path, lead_provider: old_lead_provider, params:) }
          .not_to(change { application.reload.status })

        expect(response).to be_forbidden
      end
    end
  end

  describe "POST /api/v1/applications/:ecf_id/declarations/started" do
    let(:resource) { create(:application, :accepted, cohort:, lead_provider: current_lead_provider) }
    let(:declaration_date) { schedule.training_starts_at + 1.hour }
    let(:cohort) { create(:cohort) }
    let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now, cohort:) }
    let(:has_passed) { true }
    let(:delivery_partner_id) do
      create(:delivery_partner, lead_providers: { cohort => current_lead_provider }).ecf_id
    end
    let(:secondary_delivery_partner_id) do
      create(:delivery_partner, lead_providers: { cohort => current_lead_provider }).ecf_id
    end

    let(:resource_id) { resource.ecf_id }
    let(:service) { Declarations::Create }
    let(:action) { :call }
    let(:attributes) do
      {
        declaration_date: declaration_date.rfc3339,
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end
    let(:service_args) do
      {
        application: resource,
        declaration_type: :started,
        declaration_date: declaration_date.rfc3339,
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end
    let(:declaration) { create(:declaration) }
    let(:service_methods) { { declaration: } }
    let(:serializer) { API::DeclarationSerializer }

    def path(id = resource_id)
      started_declaration_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API create endpoint"

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { started_declaration_api_v1_application_path(ecf_id: application.ecf_id) }
      let(:params) { { data: { attributes: } } }

      it "the old provider cannot create the declaration" do
        expect { api_post(path, lead_provider: old_lead_provider, params:) }
          .not_to(change(Declaration, :count))

        expect(response).to be_forbidden
      end
    end
  end

  describe "POST /api/v1/applications/:ecf_id/declarations/completed" do
    let(:resource) { create(:application, :with_declaration, lead_provider: current_lead_provider) }
    let(:declaration_date) { schedule.training_starts_at + 1.hour }
    let(:schedule) { create(:schedule, cohort: resource.cohort, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
    let(:has_passed) { true }
    let(:delivery_partner_id) do
      create(:delivery_partner, lead_providers: { resource.cohort => current_lead_provider }).ecf_id
    end
    let(:secondary_delivery_partner_id) do
      create(:delivery_partner, lead_providers: { resource.cohort => current_lead_provider }).ecf_id
    end

    let(:resource_id) { resource.ecf_id }
    let(:service) { Declarations::Create }
    let(:action) { :call }

    let(:attributes) do
      {
        declaration_date: declaration_date.rfc3339,
        has_passed:,
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end
    let(:service_args) do
      {
        application: resource,
        declaration_type: :completed,
        declaration_date: declaration_date.rfc3339,
        has_passed:,
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end
    let(:declaration) { create(:declaration) }
    let(:service_methods) { { declaration: } }
    let(:serializer) { API::DeclarationSerializer }

    def path(id = resource_id)
      completed_declaration_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API create endpoint"

    context "when an application changed provider" do
      include_context "with application which changed provider"
      let(:path) { completed_declaration_api_v1_application_path(ecf_id: application.ecf_id) }
      let(:params) { { data: { attributes: } } }
      let(:declaration_date) { application.cohort.training_starts_at + 1.hour }
      let(:delivery_partner_id) do
        create(:delivery_partner, lead_providers: { application.cohort => current_lead_provider }).ecf_id
      end
      let(:secondary_delivery_partner_id) do
        create(:delivery_partner, lead_providers: { application.cohort => current_lead_provider }).ecf_id
      end

      it "the old provider cannot create the declaration" do
        expect { api_post(path, lead_provider: old_lead_provider, params:) }
          .not_to(change(Declaration, :count))

        expect(response).to be_forbidden
      end
    end
  end
end
