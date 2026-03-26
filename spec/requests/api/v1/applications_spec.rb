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
    let(:expected_data_id) { application.ecf_id }
    let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
    let!(:course_cohort) { create(:course_cohort, lead_provider: current_lead_provider, schedule:) }
    let(:application_status_trait) { :started }
    let(:application) { create(:application, application_status_trait, :with_declaration, lead_provider: current_lead_provider, course: course_cohort.course) }
    let(:params) { { data: { attributes: { reason: "career-break" } } } }

    before do
      api_put(defer_api_v1_application_path(ecf_id: application.ecf_id), params:)
    end

    context "when the application can be deferred" do
      it_behaves_like "a successful api call"
    end

    context "when the application cannot be deferred" do
      let(:application_status_trait) { :deferred }
      let(:expected_response) do
        {
          "errors" => [
            { "title" => "base", "detail" => I18n.t("activemodel.errors.models.applications/defer.attributes.base.already_deferred") },
          ],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/resume" do
    let(:expected_data_id) { application.ecf_id }
    let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
    let!(:course_cohort) { create(:course_cohort, lead_provider: current_lead_provider, schedule:) }
    let(:application_status_trait) { :deferred }
    let(:application) { create(:application, application_status_trait, lead_provider: current_lead_provider, course: course_cohort.course) }
    let(:params) { { data: { attributes: { schedule_id: course_cohort.ecf_id } } } }

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
            { "title" => "base", "detail" => I18n.t("activemodel.errors.models.applications/resume.attributes.base.already_started") },
          ],
        }
      end

      it_behaves_like "an unprocessable content api call"
    end
  end

  describe "PUT /api/v1/applications/:ecf_id/withdraw" do
    let(:expected_data_id) { application.ecf_id }
    let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
    let!(:course_cohort) { create(:course_cohort, lead_provider: current_lead_provider, schedule:) }
    let(:application_status_trait) { :started }
    let(:application) { create(:application, application_status_trait, :with_declaration, lead_provider: current_lead_provider, course: course_cohort.course) }
    let(:params) { { data: { attributes: { reason: "insufficient-capacity" } } } }

    before do
      api_put(withdraw_api_v1_application_path(ecf_id: application.ecf_id), params:)
    end

    context "when the application can be withdrawn" do
      it_behaves_like "a successful api call"
    end

    context "when the application cannot be withdrawn" do
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
  end

  describe "PUT /api/v1/applications/:ecf_id/change-schedule" do
    let(:resource) { create(:application, :accepted, course_cohort:, lead_provider: current_lead_provider) }
    let(:course_cohort) { create(:course_cohort, course:, cohort:, schedule:, lead_provider: current_lead_provider) }
    let(:course) { create(:course) }
    let(:cohort) { create(:cohort, :current) }
    let(:schedule) { create(:schedule, training_starts_at: 1.month.from_now, training_ends_at: 6.months.from_now) }

    let(:target_course_cohort) do
      create(:course_cohort,
             course: target_course,
             cohort: target_cohort,
             schedule: target_schedule,
             lead_provider: current_lead_provider)
    end

    let(:target_course) { course }
    let(:target_cohort) { create(:cohort, :next) }
    let(:target_schedule) { create(:schedule, training_starts_at: 1.day.from_now, training_ends_at: 2.days.from_now, change_training_dates: false) }

    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::ChangeSchedule }
    let(:action) { :call }
    let(:attributes) { { schedule_id: target_course_cohort.ecf_id } }
    let(:service_args) { { application: resource, course_cohort: target_course_cohort } }

    def path(id = nil)
      change_schedule_api_v1_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "POST /api/v1/applications/:ecf_id/declarations/started" do
    let(:resource) { create(:application, :accepted, course_cohort:, lead_provider: current_lead_provider) }
    let(:declaration_date) { schedule.training_starts_at + 1.hour }
    let(:course_cohort) { create(:course_cohort, schedule:) }
    let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
    let(:has_passed) { true }
    let(:delivery_partner_id) do
      create(:delivery_partner, lead_providers: { course_cohort.cohort => current_lead_provider }).ecf_id
    end
    let(:secondary_delivery_partner_id) do
      create(:delivery_partner, lead_providers: { course_cohort.cohort => current_lead_provider }).ecf_id
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
  end

  describe "POST /api/v1/applications/:ecf_id/declarations/completed" do
    let(:resource) { create(:application, :with_declaration, lead_provider: current_lead_provider) }
    let(:declaration_date) { schedule.training_starts_at + 1.hour }
    let(:course_cohort) { create(:course_cohort, schedule:) }
    let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
    let(:has_passed) { true }
    let(:delivery_partner_id) do
      create(:delivery_partner, lead_providers: { course_cohort.cohort => current_lead_provider }).ecf_id
    end
    let(:secondary_delivery_partner_id) do
      create(:delivery_partner, lead_providers: { course_cohort.cohort => current_lead_provider }).ecf_id
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
  end
end
