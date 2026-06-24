# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::LateStartedDeclarationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject(:make_request) { get admin_applications_late_started_declarations_path, params: }

  before { sign_in_as_admin }

  describe "#index" do
    let(:params) { {} }
    let(:lead_provider) { create(:lead_provider, name: "Example Provider") }
    let(:other_lead_provider) { create(:lead_provider, name: "Other Provider") }
    let(:course) { create(:course, name: "Example Course") }
    let(:other_course) { create(:course, name: "Other Course") }
    let(:past_course_cohort) { course_cohort(training_starts_at: Time.zone.yesterday, course:, lead_provider:) }
    let(:other_past_course_cohort) { course_cohort(training_starts_at: 2.days.ago, course:, lead_provider:) }
    let(:other_course_past_course_cohort) { course_cohort(training_starts_at: 3.days.ago, course: other_course, lead_provider:) }
    let(:other_lead_provider_past_course_cohort) { course_cohort(training_starts_at: 4.days.ago, course:, lead_provider: other_lead_provider) }
    let(:today_course_cohort) { course_cohort(training_starts_at: Time.zone.today, course:, lead_provider:) }
    let(:future_course_cohort) { course_cohort(training_starts_at: Time.zone.tomorrow, course:, lead_provider:) }

    let!(:late_started_declaration_application) do
      create(:application, :accepted, course_cohort: past_course_cohort, lead_provider:)
    end
    let!(:other_late_started_declaration_application) do
      create(:application, :accepted, course_cohort: other_past_course_cohort, lead_provider:)
    end
    let!(:other_course_late_started_declaration_application) do
      create(:application, :accepted, course_cohort: other_course_past_course_cohort, lead_provider:)
    end
    let!(:other_lead_provider_late_started_declaration_application) do
      create(:application, :accepted, course_cohort: other_lead_provider_past_course_cohort, lead_provider: other_lead_provider)
    end
    let!(:rejected_late_started_declaration_application) do
      create(:application, :rejected, course_cohort: past_course_cohort, lead_provider:)
    end
    let!(:withdrawn_late_started_declaration_application) do
      create(:application, :withdrawn, course_cohort: past_course_cohort, lead_provider:)
    end

    before do
      application_with_started_declaration = create(:application, :accepted, course_cohort: past_course_cohort, lead_provider:)
      create(:declaration, :started, application: application_with_started_declaration)

      create(:application, :accepted, course_cohort: today_course_cohort, lead_provider:)
      create(:application, :accepted, course_cohort: future_course_cohort, lead_provider:)
    end

    it "lists applications whose training has started and have no started declaration" do
      make_request

      expect(assigns[:applications]).to contain_exactly(
        late_started_declaration_application,
        other_late_started_declaration_application,
        other_course_late_started_declaration_application,
        other_lead_provider_late_started_declaration_application,
      )
      expect(assigns[:applications]).not_to include(rejected_late_started_declaration_application)
      expect(assigns[:applications]).not_to include(withdrawn_late_started_declaration_application)
      expect(response).to have_http_status(:ok)
    end

    it "renders sidebar links" do
      make_request

      expect(response.body).to include("Cohorts")
      expect(response.body).to include(past_course_cohort.cohort.description)
      expect(response.body).to include(other_past_course_cohort.cohort.description)
      expect(response.body).to include(admin_applications_late_started_declarations_path(cohort_id: past_course_cohort.cohort.id))
      expect(response.body).to include("Courses")
      expect(response.body).to include("Example Course")
      expect(response.body).to include("Other Course")
      expect(response.body).to include(admin_applications_late_started_declarations_path(course_id: course.id))
      expect(response.body).to include("Lead providers")
      expect(response.body).to include("Example Provider")
      expect(response.body).to include("Other Provider")
      expect(response.body).to include(admin_applications_late_started_declarations_path(lead_provider_id: lead_provider.id))
      expect(response.body).to include("Statuses")
      expect(response.body).to include("Accepted")
      expect(response.body).to include(admin_applications_late_started_declarations_path(status: Application::ACCEPTED))
    end

    it "renders a CSV download link" do
      make_request

      expect(response.body).to include("Download as CSV")
      expect(response.body).to include(admin_applications_late_started_declarations_path(format: :csv))
    end

    it "downloads the filtered report as CSV" do
      get admin_applications_late_started_declarations_path(format: :csv), params: { course_id: course.id }

      csv = CSV.parse(response.body, headers: true)

      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("late_started_declarations.csv")
      expect(csv.headers).to eq([
        "User",
        "Application status",
        "Provider",
        "Course",
        "Cohort",
        "Expected by",
      ])
      expect(csv["User"]).to contain_exactly(
        late_started_declaration_application.user.full_name,
        other_late_started_declaration_application.user.full_name,
        other_lead_provider_late_started_declaration_application.user.full_name,
      )
    end

    context "when viewing a later page with an active filter" do
      let(:params) { { page: 2, status: Application::ACCEPTED } }

      it "removes the page param from filter links" do
        make_request

        filter_path = admin_applications_late_started_declarations_path(
          cohort_id: past_course_cohort.cohort.id,
          status: Application::ACCEPTED,
        )
        paged_filter_path = admin_applications_late_started_declarations_path(
          cohort_id: past_course_cohort.cohort.id,
          page: 2,
          status: Application::ACCEPTED,
        )

        expect(response.body).to include(ERB::Util.html_escape(filter_path))
        expect(response.body).not_to include(ERB::Util.html_escape(paged_filter_path))
      end
    end

    context "when filtering by cohort" do
      let(:params) { { cohort_id: past_course_cohort.cohort.id } }

      it "lists applications for the selected cohort" do
        make_request

        expect(assigns[:applications]).to contain_exactly(late_started_declaration_application)
        expect(response.body).to include(late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(other_late_started_declaration_application.user.full_name)
      end
    end

    context "when filtering by course" do
      let(:params) { { course_id: course.id } }

      it "lists applications for the selected course" do
        make_request

        expect(assigns[:applications]).to contain_exactly(
          late_started_declaration_application,
          other_late_started_declaration_application,
          other_lead_provider_late_started_declaration_application,
        )
        expect(response.body).to include(late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(other_course_late_started_declaration_application.user.full_name)
      end
    end

    context "when filtering by cohort and course" do
      let(:params) { { cohort_id: past_course_cohort.cohort.id, course_id: course.id } }

      it "lists applications matching both filters" do
        make_request

        expect(assigns[:applications]).to contain_exactly(late_started_declaration_application)
        expect(response.body).to include(late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(other_late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(other_course_late_started_declaration_application.user.full_name)
      end
    end

    context "when filtering by lead provider" do
      let(:params) { { lead_provider_id: other_lead_provider.id } }

      it "lists applications for the selected lead provider" do
        make_request

        expect(assigns[:applications]).to contain_exactly(other_lead_provider_late_started_declaration_application)
        expect(response.body).to include(other_lead_provider_late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(late_started_declaration_application.user.full_name)
      end
    end

    context "when filtering by status" do
      let(:params) { { status: Application::REJECTED } }

      it "does not list rejected applications" do
        make_request

        expect(assigns[:applications]).to be_empty
        expect(response.body).not_to include(rejected_late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(late_started_declaration_application.user.full_name)
      end
    end

    context "when filtering by withdrawn status" do
      let(:params) { { status: Application::WITHDRAWN } }

      it "does not list withdrawn applications" do
        make_request

        expect(assigns[:applications]).to be_empty
        expect(response.body).not_to include(withdrawn_late_started_declaration_application.user.full_name)
      end
    end

    context "when filtering by all filters" do
      let(:params) do
        {
          cohort_id: past_course_cohort.cohort.id,
          course_id: course.id,
          lead_provider_id: lead_provider.id,
          status: Application::ACCEPTED,
        }
      end

      it "lists applications matching every filter" do
        make_request

        expect(assigns[:applications]).to contain_exactly(late_started_declaration_application)
        expect(response.body).to include(late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(rejected_late_started_declaration_application.user.full_name)
        expect(response.body).not_to include(other_lead_provider_late_started_declaration_application.user.full_name)
      end
    end

    it "renders the report columns" do
      make_request

      expect(response.body).to include(late_started_declaration_application.user.full_name)
      expect(response.body).to include(late_started_declaration_application.status.humanize)
      expect(response.body).to include("Example Provider")
      expect(response.body).to include("Example Course")
      expect(response.body).to include(past_course_cohort.cohort.description)
    end
  end

private

  def course_cohort(training_starts_at:, course:, lead_provider:)
    cohort = create(:cohort, :unique)
    schedule = create(:schedule,
                      cohort:,
                      training_starts_at:,
                      training_ends_at: training_starts_at + 1.year,
                      change_training_dates: false)

    create(:course_cohort, course:, cohort:, schedule:, lead_provider:)
  end
end
