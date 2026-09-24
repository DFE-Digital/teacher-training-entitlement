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
        create_list(:delivery_partnership, 2, course_cohort:, lead_provider:)
        get admin_course_cohort_path(course_cohort.course, cohort)
      end

      it { is_expected.to have_http_status :success }

      it "links back to courses when there is no referrer" do
        expect(response.body).to include(%(href="#{admin_courses_path}"))
      end

      it "links back to the referrer when present" do
        referrer = admin_cohort_path(cohort)

        get admin_course_cohort_path(course_cohort.course, cohort), headers: { "HTTP_REFERER" => referrer }

        expect(response.body).to include(%(href="#{referrer}"))
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

      it "links to add or remove providers" do
        expect(response.body).to include(admin_course_course_cohort_provider_path(course, course_cohort))
      end

      it "does not link to add a milestone" do
        expect(response.body).not_to include("Add Milestone")
      end

      describe "Showing milestones" do
        it "shows milestones for the course cohort" do
          get admin_course_cohort_path(course, cohort)

          expect(response.body).to include("40%")
          expect(response.body).not_to include("Edit")
        end
      end
    end

    describe "#new" do
      before { get new_admin_cohort_course_path(cohort) }

      it { is_expected.to have_http_status :success }

      it "shows the course selection form" do
        expect(response.body).to include("Add course to cohort")
        expect(response.body).to include("Course to add")
      end
    end

    describe "#create" do
      let(:request) { post admin_cohort_courses_path(cohort), params: cohort_first_params }

      before do
        create(:contract_year, :generic, course:, lead_provider:, teacher_funding: 1000, recruitment_target: 50)
      end

      it do
        request
        expect(response).to redirect_to admin_course_cohort_path(course, cohort)
        expect(flash[:success]).to match(/Course added/i)
      end

      it "sets up complete course cohort" do
        expect { request }.to change(CourseCohort, :count).by(1)

        course_cohort = cohort.course_cohorts.find_by(course:)
        expect(course_cohort).to be_present
        expect(course_cohort.course_cohort_providers.find_by(lead_provider:)).to be_present
        expect(course_cohort.delivery_partnerships.find_by(lead_provider:, delivery_partner:)).to be_present
      end
    end

    describe "#create with invalid params" do
      before { post admin_cohort_courses_path(cohort), params: invalid_params }

      it { is_expected.to have_http_status :unprocessable_content }
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    let(:course_cohort) { create(:course_cohort, cohort:, course:, lead_provider:) }

    shared_examples "inaccessible to normal admins" do
      it { is_expected.to redirect_to admin_courses_path }

      it "flashes the correct error" do
        expect(flash[:error]).to match(/You must be a super admin/i)
      end
    end

    describe "#show" do
      before { get admin_course_cohort_path(course_cohort.course, cohort) }

      it { is_expected.to have_http_status :success }
    end

    describe "#new" do
      before { get new_admin_cohort_course_path(cohort) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#create" do
      before { post admin_cohort_courses_path(cohort), params: cohort_first_params }

      it_behaves_like "inaccessible to normal admins"
    end
  end

  context "when not logged in" do
    let(:course_cohort) { create(:course_cohort, cohort:, course:, lead_provider:) }

    describe "#show" do
      before { get admin_course_cohort_path(course_cohort.course, cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#new" do
      before { get new_admin_cohort_course_path(cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post admin_cohort_courses_path(cohort), params: cohort_first_params }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
