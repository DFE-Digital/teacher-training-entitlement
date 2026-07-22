require "rails_helper"
require "swagger_helper"

RSpec.describe "Applications endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"
  let(:course) { create(:course, :npd_eirt) }
  let(:schedule) { create(:schedule, :tte_reception_autumn) }
  let(:course_cohort) { create(:course_cohort, course:, schedule:) }
  let(:application) { create(:application, lead_provider:, course_cohort:) }

  describe "list applications" do
    it_behaves_like "an API index endpoint documentation",
                    "/api/v1/applications",
                    "Applications",
                    "applications",
                    "#/components/schemas/ListApplicationsFilter",
                    "#/components/schemas/ApplicationsResponse",
                    true
  end

  describe "show single application" do
    it_behaves_like "an API show endpoint documentation",
                    "/api/v1/applications/{id}",
                    "Applications",
                    "application",
                    "#/components/schemas/ApplicationResponse" do
      let(:resource) { application }
    end
  end

  describe "application actions" do
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/ApplicationResponse", version: :v1)
    end

    describe "accept application" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/applications/{id}/accept",
                      "Applications",
                      "Accept an application",
                      "The application being accepted",
                      "#/components/schemas/ApplicationResponse",
                      "#/components/schemas/ApplicationAcceptRequest" do
        let(:resource) { application }
        let(:type) { "application" }
        let(:attributes) { { funded_place: false } }
        let(:invalid_attributes) { { funded_place: nil } }
        let(:response_example) do
          base_response_example.tap do |example|
            example[:data][:attributes][:status] = "accepted"
            example[:data][:attributes][:funded_place] = true
          end
        end
      end
    end

    describe "reject application" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/applications/{id}/reject",
                      "Applications",
                      "Reject an application",
                      "The application being rejected",
                      "#/components/schemas/ApplicationResponse" do
        let(:resource) { application }
        let(:type) { "application" }
        let(:response_example) do
          base_response_example.tap do |example|
            example[:data][:attributes][:status] = "rejected"
          end
        end
      end
    end

    # change_funded_place
    describe "change accepted application funded_place" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/applications/{id}/change-funded-place",
                      "Applications",
                      "Change funded place value of an application",
                      "The application after changing the funded place",
                      "#/components/schemas/ApplicationResponse",
                      "#/components/schemas/ApplicationChangeFundedPlaceRequest" do
        let(:application) { create(:application, :accepted, :eligible_for_funding, lead_provider:, course_cohort:) }
        let(:resource) { application }
        let(:type) { "application" }
        let(:attributes) { { funded_place: true } }
        let(:invalid_attributes) { { funded_place: nil } }
        let(:response_example) do
          base_response_example.tap do |example|
            example[:data][:attributes][:status] = "accepted"
            example[:data][:attributes][:funded_place] = true
          end
        end
      end
    end

    describe "defer an application" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/applications/{id}/defer",
                      "Applications",
                      "Defer an application",
                      "The application being deferred",
                      "#/components/schemas/ApplicationResponse",
                      "#/components/schemas/ApplicationDeferRequest" do
        let(:application) { create(:application, :started, :with_declaration, :eligible_for_funding, lead_provider:, course_cohort:) }
        let(:resource) { application }
        let(:type) { "application" }
        let(:attributes) { { reason: ::Applications::Defer::DEFERRAL_REASONS.first } }
        let(:invalid_attributes) { { reason: nil } }
        let(:response_example) do
          base_response_example.tap do |example|
            example[:data][:attributes][:status] = "deferred"
            example[:data][:attributes][:funded_place] = true
          end
        end
      end
    end

    describe "resume an application" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/applications/{id}/resume",
                      "Applications",
                      "Resume an application",
                      "The application being resumed",
                      "#/components/schemas/ApplicationResponse",
                      "#/components/schemas/ApplicationResumeRequest" do
        let(:application) { create(:application, :deferred, :with_declaration, :eligible_for_funding, lead_provider:, course_cohort:) }
        let(:target_course_cohort) do
          create(:course_cohort,
                 course: course_cohort.course,
                 cohort: create(:cohort, :current),
                 schedule: target_schedule,
                 lead_provider: application.lead_provider)
        end
        let(:target_schedule) { create(:schedule, :tte_reception_autumn, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now, change_training_dates: false) }

        let(:resource) { application }
        let(:type) { "application" }
        let(:attributes) { { schedule_id: target_course_cohort.ecf_id } }
        let(:invalid_attributes) { { schedule_id: nil } }
        let(:response_example) do
          base_response_example.tap do |example|
            example[:data][:attributes][:status] = "started"
            example[:data][:attributes][:funded_place] = true
          end
        end
      end
    end

    describe "withdraw an application" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/applications/{id}/withdraw",
                      "Applications",
                      "Withdraw an application",
                      "The application being withdrawn",
                      "#/components/schemas/ApplicationResponse",
                      "#/components/schemas/ApplicationWithdrawRequest" do
        let(:application) { create(:application, :started, :with_declaration, :eligible_for_funding, lead_provider:, course_cohort:) }
        let(:resource) { application }
        let(:type) { "application" }
        let(:attributes) { { reason: ::Applications::Withdraw::WITHDRAWAL_REASONS.first } }
        let(:invalid_attributes) { { reason: nil } }
        let(:response_example) do
          base_response_example.tap do |example|
            example[:data][:attributes][:status] = "withdrawn"
          end
        end
      end
    end

    describe "change an accepted application schedule" do
      it_behaves_like "an API update endpoint documentation",
                      "/api/v1/applications/{id}/change-schedule",
                      "Applications",
                      "Change the schedule of an application",
                      "The application's schedule being changed",
                      "#/components/schemas/ApplicationResponse",
                      "#/components/schemas/ApplicationChangeScheduleRequest" do
        let(:application) { create(:application, :accepted, :eligible_for_funding, lead_provider:, course_cohort:) }
        let(:target_course_cohort) do
          create(:course_cohort,
                 course: course_cohort.course,
                 cohort: create(:cohort, :next),
                 schedule: target_schedule,
                 lead_provider: application.lead_provider)
        end
        let(:target_schedule) { create(:schedule, :tte_reception_spring, training_starts_at: 1.day.from_now, training_ends_at: 2.days.from_now, change_training_dates: false) }

        let(:resource) { application }
        let(:type) { "application" }
        let(:attributes) { { schedule_id: target_course_cohort.ecf_id } }
        let(:invalid_attributes) { { schedule_id: nil } }
        let(:response_example) do
          base_response_example.tap do |example|
            example[:data][:attributes][:status] = "accepted"
            example[:data][:attributes][:funded_place] = true
          end
        end
      end
    end

    describe "started declaration" do
      it_behaves_like "an API create on existing resource endpoint documentation",
                      "/api/v1/applications/{id}/declarations/started",
                      "Applications",
                      "Declare an application has reached the course started milestone",
                      "The application being started declaration being created",
                      "#/components/schemas/DeclarationResponse",
                      "#/components/schemas/DeclarationStartedRequest" do
        let(:application) { create(:application, :accepted, lead_provider:, course_cohort:) }
        let(:resource) { application }
        let(:declaration_date) { schedule.training_starts_at + 1.hour }
        let(:schedule) { create(:schedule, :tte_reception_autumn, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
        let(:delivery_partner_id) do
          create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
        end
        let(:secondary_delivery_partner_id) do
          create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
        end

        let(:type) { "declaration" }
        let(:attributes) do
          {
            declaration_date: schedule.training_starts_at.rfc3339,
            delivery_partner_id:,
            secondary_delivery_partner_id:,

          }
        end
        let(:invalid_attributes) { { declaration_date: nil } }

        before { create(:milestone, :started, course_cohort:) }
      end
    end

    describe "completed declaration" do
      it_behaves_like "an API create on existing resource endpoint documentation",
                      "/api/v1/applications/{id}/declarations/completed",
                      "Applications",
                      "Declare an application has reached the course started milestone",
                      "The application being started declaration being created",
                      "#/components/schemas/DeclarationResponse",
                      "#/components/schemas/DeclarationCompletedRequest" do
        let(:application) do
          create(:application, :started, :with_declaration, course_cohort:, lead_provider:)
        end
        let(:resource) { application }
        let(:declaration_date) { schedule.training_starts_at + 1.hour }
        let(:schedule) do
          create(:schedule, :tte_reception_autumn, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now)
        end
        let(:delivery_partner_id) do
          create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
        end
        let(:secondary_delivery_partner_id) do
          create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
        end

        let(:type) { "declaration" }
        let(:attributes) do
          {
            declaration_date: schedule.training_starts_at.rfc3339,
            has_passed: true,
            delivery_partner_id:,
            # secondary_delivery_partner_id:,
          }
        end
        let(:invalid_attributes) { { declaration_date: nil } }

        before do
          create(:milestone, :started, course_cohort:)
          create(:milestone, :completed, course_cohort:)
        end
      end
    end
  end
end
