# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::LateCompletedDeclarationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject(:make_request) { get admin_applications_late_completed_declarations_path, params: }

  before { sign_in_as_admin }

  describe "#index" do
    let(:params) { {} }
    let(:lead_provider) { create(:lead_provider, name: "Example Provider") }
    let(:other_lead_provider) { create(:lead_provider, name: "Other Provider") }
    let(:course) { create(:course, name: "Example Course") }
    let(:other_course) { create(:course, name: "Other Course") }
    let(:past_course_cohort) { course_cohort(training_ends_at: Time.zone.yesterday, course:, lead_provider:) }
    let(:other_course_cohort) { course_cohort(training_ends_at: 2.days.ago, course: other_course, lead_provider: other_lead_provider) }
    let(:today_course_cohort) { course_cohort(training_ends_at: Time.zone.today, course:, lead_provider:) }
    let(:future_course_cohort) { course_cohort(training_ends_at: Time.zone.tomorrow, course:, lead_provider:) }

    let!(:late_completed_declaration_application) do
      create(:application, :accepted, course_cohort: past_course_cohort, lead_provider:).tap do |application|
        create(:declaration, :started, application:)
      end
    end
    let!(:other_late_completed_declaration_application) do
      create(:application, :deferred, course_cohort: other_course_cohort, lead_provider: other_lead_provider).tap do |application|
        create(:declaration, :started, application:)
      end
    end
    let!(:rejected_late_completed_declaration_application) do
      create(:application, :rejected, course_cohort: past_course_cohort, lead_provider:).tap do |application|
        create(:declaration, :started, application:)
      end
    end
    let!(:withdrawn_late_completed_declaration_application) do
      create(:application, :withdrawn, course_cohort: past_course_cohort, lead_provider:)
    end
    let!(:application_without_started_declaration) do
      create(:application, :accepted, course_cohort: past_course_cohort, lead_provider:)
    end

    before do
      application_with_completed_declaration = create(:application, :accepted, course_cohort: past_course_cohort, lead_provider:)
      create(:declaration, :started, application: application_with_completed_declaration)
      create(:declaration, :completed, application: application_with_completed_declaration)

      create(:application, :accepted, course_cohort: today_course_cohort, lead_provider:)
      create(:application, :accepted, course_cohort: future_course_cohort, lead_provider:)
    end

    it "lists applications whose training has ended, have started and have no completed declaration" do
      make_request

      expect(assigns[:applications]).to contain_exactly(
        late_completed_declaration_application,
        other_late_completed_declaration_application,
      )
      expect(assigns[:applications]).not_to include(rejected_late_completed_declaration_application)
      expect(assigns[:applications]).not_to include(withdrawn_late_completed_declaration_application)
      expect(assigns[:applications]).not_to include(application_without_started_declaration)
      expect(response).to have_http_status(:ok)
    end

    it "uses completed report copy and links" do
      make_request

      expect(response.body).to include("Late completed declarations")
      expect(response.body).to include("training has ended")
      expect(response.body).to include("a started declaration has been submitted")
      expect(response.body).to include(admin_applications_late_completed_declarations_path(course_id: course.id))
      expect(response.body).to include(admin_applications_late_completed_declarations_path(status: Application::ACCEPTED))
    end

    it "renders a CSV download link" do
      make_request

      expect(response.body).to include("Download as CSV")
      expect(response.body).to include(admin_applications_late_completed_declarations_path(format: :csv))
    end

    it "downloads the filtered report as CSV" do
      get admin_applications_late_completed_declarations_path(format: :csv), params: { lead_provider_id: lead_provider.id }

      csv = CSV.parse(response.body, headers: true)

      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("late_completed_declarations.csv")
      expect(csv.headers).to eq([
        "User",
        "Application status",
        "Provider",
        "Course",
        "Cohort",
        "Expected by",
      ])
      expect(csv["User"]).to contain_exactly(late_completed_declaration_application.user.full_name)
    end

    context "when filtering by lead provider" do
      let(:params) { { lead_provider_id: lead_provider.id } }

      it "lists applications for the selected lead provider" do
        make_request

        expect(assigns[:applications]).to contain_exactly(late_completed_declaration_application)
        expect(response.body).to include(late_completed_declaration_application.user.full_name)
        expect(response.body).not_to include(other_late_completed_declaration_application.user.full_name)
      end
    end

    context "when filtering by all filters" do
      let(:params) do
        {
          cohort_id: other_course_cohort.cohort.id,
          course_id: other_course.id,
          lead_provider_id: other_lead_provider.id,
          status: Application::DEFERRED,
        }
      end

      it "lists applications matching every filter" do
        make_request

        expect(assigns[:applications]).to contain_exactly(other_late_completed_declaration_application)
        expect(response.body).to include(other_late_completed_declaration_application.user.full_name)
        expect(response.body).not_to include(late_completed_declaration_application.user.full_name)
      end
    end

    context "when filtering by rejected status" do
      let(:params) { { status: Application::REJECTED } }

      it "does not list rejected applications" do
        make_request

        expect(assigns[:applications]).to be_empty
        expect(response.body).not_to include(rejected_late_completed_declaration_application.user.full_name)
      end
    end

    context "when filtering by withdrawn status" do
      let(:params) { { status: Application::WITHDRAWN } }

      it "does not list withdrawn applications" do
        make_request

        expect(assigns[:applications]).to be_empty
        expect(response.body).not_to include(withdrawn_late_completed_declaration_application.user.full_name)
      end
    end
  end

private

  def course_cohort(training_ends_at:, course:, lead_provider:)
    cohort = create(:cohort, :unique)
    schedule = create(
      :schedule,
      cohort:,
      training_starts_at: training_ends_at - 1.year,
      training_ends_at:,
      change_training_dates: false,
    )

    create(:course_cohort, course:, cohort:, schedule:, lead_provider:)
  end
end
