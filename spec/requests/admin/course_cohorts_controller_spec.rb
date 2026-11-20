require "rails_helper"

RSpec.describe Admin::CourseCohortsController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 5, 1)) }
  let!(:course) { create(:course, name: "Course to add", identifier: "course-to-add") }
  let(:lead_provider) { create(:lead_provider, name: "Provider One") }
  let!(:delivery_partner) { create(:delivery_partner, lead_providers: [lead_provider]) }

  let(:cohort_first_params) do
    {
      course_cohorts_setup_form: {
        course_id: course.id,
        "training_starts_at(1i)": "2025",
        "training_starts_at(2i)": "9",
        "training_starts_at(3i)": "1",
      },
    }
  end
  let(:invalid_params) do
    {
      course_cohorts_setup_form: {
        course_id: "",
        "training_starts_at(1i)": "",
        "training_starts_at(2i)": "",
        "training_starts_at(3i)": "",
        lead_providers: {},
      },
    }
  end

  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    let(:course_cohort) { create(:course_cohort, cohort:, course:, lead_provider:) }

    describe "#show" do
      before do
        create_list(:delivery_partnership, 2, course:, lead_provider:)
        get cohort_admin_course_cohort_path(course_cohort.course, cohort)
      end

      it { is_expected.to have_http_status :success }

      it "links back" do
        expect(response.body).to include(%(href="#{cohort_admin_course_cohorts_path(course_cohort.cohort)}"))
      end

      it "shows the cohort name" do
        expect(response.body).to include(cohort.name)
      end

      it "links to providers on the course cohort" do
        expect(response.body).to include(cohort_admin_lead_provider_path(lead_provider, cohort))
      end

      it "shows the number of delivery partners for the provider and cohort" do
        expect(response.body).to include("2 delivery partners")
      end

      it "does not count archived delivery partnerships" do
        create(:delivery_partnership, course:, lead_provider:, archived_at: 1.day.ago)
        get cohort_admin_course_cohort_path(course_cohort.course, cohort)

        expect(response.body).to include("2 delivery partners")
      end

      it "links to add or remove providers" do
        expect(response.body).to include("Add/Remove providers")
        expect(response.body).to include(admin_course_cohort_provider_path(course_cohort))
      end

      it "does not link to add a milestone" do
        expect(response.body).not_to include("Add Milestone")
      end

      describe "Showing milestones" do
        it "shows milestones for the course cohort" do
          get cohort_admin_course_cohort_path(course, cohort)

          expect(response.body).to include("40%")
          expect(response.body).not_to include("Edit")
        end
      end
    end

    describe "#show uplift details" do
      let(:other_lead_provider) { create(:lead_provider, name: "Provider Two") }

      before do
        create(:course_cohort_provider, course_cohort:, lead_provider: other_lead_provider)
      end

      context "when the course is set up with uplift details" do
        before do
          create(:contract_year, :generic, course:, lead_provider:, uplift_percentage: BigDecimal("0.1"))
          create(:contract_year, :generic, course:, lead_provider: other_lead_provider, uplift_percentage: BigDecimal("0.125"))
          create(:course_uplift_institution, course:, institution: create(:institution, name: "Uplift School"))

          get cohort_admin_course_cohort_path(course, cohort)
        end

        it "shows the uplift incentive as yes" do
          expect(summary_value("Uplift incentive")).to eq("Yes")
        end

        it "shows the uplift percentage of each provider" do
          expect(provider_uplift_percentages).to eq("Provider One" => "10%", "Provider Two" => "12.5%")
        end

        it "lists the uplift institutions in a details section" do
          details = Nokogiri::HTML(response.body).at_css("details#uplift-institutions")

          expect(details.at_css("summary").text).to include("Uplift institutions")
          expect(details.text).to include("Uplift School")
        end
      end

      context "when the course is not set up with uplift details" do
        before do
          create(:contract_year, :generic, course:, lead_provider:)

          get cohort_admin_course_cohort_path(course, cohort)
        end

        it "shows the uplift incentive as no" do
          expect(summary_value("Uplift incentive")).to eq("No")
        end

        it "shows a placeholder for the uplift percentage of each provider" do
          expect(provider_uplift_percentages).to eq("Provider One" => "-", "Provider Two" => "-")
        end

        it "has no uplift institutions details section" do
          expect(response.body).not_to include("Uplift institutions")
        end
      end
    end

    describe "#new" do
      before { get new_admin_course_cohorts_path(cohort) }

      it { is_expected.to have_http_status :success }

      it "shows the course selection form" do
        expect(response.body).to include("Add course to cohort")
        expect(response.body).to include("Course to add")
      end
    end

    describe "#create" do
      let(:request) { post cohort_admin_course_cohorts_path(cohort), params: cohort_first_params }

      before do
        create(:contract_year, :generic, course:, lead_provider:, teacher_funding: 1000, recruitment_target: 50)
      end

      it do
        request
        expect(response).to redirect_to cohort_admin_course_cohort_path(course, cohort)
        expect(flash[:success]).to match(/Course added/i)
      end

      it "sets up complete course cohort" do
        expect { request }.to change(CourseCohort, :count).by(1)

        course_cohort = cohort.course_cohorts.find_by(course:)
        expect(course_cohort).to be_present
        expect(course_cohort.course_cohort_providers.find_by(lead_provider:)).to be_present
        expect(course_cohort.active_delivery_partnerships.find_by(lead_provider:, delivery_partner:)).to be_nil
      end

      context "when the cohort academic year differs from the training start year" do
        let(:cohort) { create(:cohort, registration_starts_at: Date.new(2026, 7, 1), start_year: 2026) }
        let(:cohort_first_params) do
          {
            course_cohorts_setup_form: {
              course_id: course.id,
              "training_starts_at(1i)": "2026",
              "training_starts_at(2i)": "10",
              "training_starts_at(3i)": "1",
            },
          }
        end

        it "uses the cohort start year for the course cohort academic year" do
          request

          expect(cohort.course_cohorts.find_by(course:).academic_year).to eq(2026)
        end
      end
    end

    describe "#create with invalid params" do
      before { post cohort_admin_course_cohorts_path(cohort), params: invalid_params }

      it { is_expected.to have_http_status :unprocessable_content }
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    let(:course_cohort) { create(:course_cohort, cohort:, course:, lead_provider:) }

    shared_examples "inaccessible to normal admins" do
      it { is_expected.to redirect_to sign_in_path }

      it "flashes the unauthorized alert" do
        expect(flash[:alert]).to eq({ title: "Unauthorized", message: "Sign in with your administrator account" })
      end
    end

    describe "#show" do
      before { get cohort_admin_course_cohort_path(course_cohort.course, cohort) }

      it { is_expected.to have_http_status :success }

      it "no links to add or remove providers" do
        expect(response.body).not_to include("Add/Remove providers")
      end
    end

    describe "#new" do
      before { get new_admin_course_cohorts_path(cohort) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#create" do
      before { post cohort_admin_course_cohorts_path(cohort), params: cohort_first_params }

      it_behaves_like "inaccessible to normal admins"
    end
  end

  context "when not logged in" do
    let(:course_cohort) { create(:course_cohort, cohort:, course:, lead_provider:) }

    describe "#show" do
      before { get cohort_admin_course_cohort_path(course_cohort.course, cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#new" do
      before { get new_admin_course_cohorts_path(cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post cohort_admin_course_cohorts_path(cohort), params: cohort_first_params }

      it { is_expected.to redirect_to sign_in_path }
    end
  end

  def summary_value(key)
    Nokogiri::HTML(response.body)
      .css(".govuk-summary-list__row")
      .find { |row| row.at_css(".govuk-summary-list__key").text.strip == key }
      .at_css(".govuk-summary-list__value")
      .text
      .strip
  end

  def provider_uplift_percentages
    table = Nokogiri::HTML(response.body)
      .css("table")
      .find { |t| t.css("thead th").map { |th| th.text.strip }.include?("Uplift percentage") }
    headers = table.css("thead th").map { |th| th.text.strip }
    provider_index = headers.index("Provider")
    uplift_index = headers.index("Uplift percentage")

    table.css("tbody tr").to_h do |row|
      cells = row.css("td, th").map { |cell| cell.text.strip }
      [cells[provider_index], cells[uplift_index]]
    end
  end
end
