require "rails_helper"

RSpec.describe Admin::CohortCoursesController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 5, 1)) }
  let!(:schedule) { create(:schedule, cohort:) }
  let!(:course) { create(:course, name: "Course to add", identifier: "course-to-add") }
  let(:lead_provider) { create(:lead_provider, name: "Provider One") }
  let(:course_cohort) { create(:course_cohort, cohort:, course:, schedule:, lead_provider:) }

  let(:valid_params) { { course_cohort: { course_id: course.id, schedule_id: schedule.id } } }
  let(:invalid_params) { { course_cohort: { course_id: "", schedule_id: "" } } }

  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    describe "#show" do
      before do
        create_list(:delivery_partnership, 2, course_cohort:, lead_provider:)
        get admin_cohort_course_path(cohort, course_cohort.course)
      end

      it { is_expected.to have_http_status :success }

      it "links back to courses when there is no referrer" do
        expect(response.body).to include(%(href="#{admin_courses_path}"))
      end

      it "links back to the referrer when present" do
        referrer = admin_cohort_path(cohort)

        get admin_cohort_course_path(cohort, course_cohort.course), headers: { "HTTP_REFERER" => referrer }

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

      it "links to add a milestone" do
        expect(response.body).to include(new_admin_cohort_course_milestone_path(cohort, course))
      end

      describe "Showing milestones" do
        let!(:milestone) do
          create(:milestone,
                 course_cohort:,
                 payment_amount: 123.45)
        end

        it "shows milestones for the course cohort" do
          get admin_cohort_course_path(cohort, course)

          expect(response.body).to include("£123.45")
          expect(response.body).to include(edit_admin_cohort_course_milestone_path(cohort, course, milestone))
        end
      end
    end

    describe "#new" do
      before { get new_admin_cohort_course_path(cohort) }

      it { is_expected.to have_http_status :success }

      it "shows schedules for the cohort" do
        expect(response.body).to include(schedule.name)
      end

      it "links to create a schedule in a new tab" do
        expect(response.body).to include(new_admin_cohort_schedule_path(cohort))
        expect(response.body).to include('target="_blank"')
      end
    end

    describe "#create" do
      before { post admin_cohort_courses_path(cohort), params: valid_params }

      it { is_expected.to redirect_to admin_cohort_course_path(cohort, course) }

      it "creates the course cohort" do
        expect(cohort.course_cohorts.find_by(course:, schedule:)).to be_present
      end

      it "flashes success" do
        expect(flash[:success]).to match(/Course added/i)
      end
    end

    describe "#create with invalid params" do
      before { post admin_cohort_courses_path(cohort), params: invalid_params }

      it { is_expected.to have_http_status :unprocessable_content }
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    shared_examples "inaccessible to normal admins" do
      it { is_expected.to redirect_to admin_cohort_path(cohort) }

      it "flashes the correct error" do
        expect(flash[:error]).to match(/You must be a super admin to change cohort courses/i)
      end
    end

    describe "#show" do
      before { get admin_cohort_course_path(cohort, course_cohort.course) }

      it { is_expected.to have_http_status :success }
    end

    describe "#new" do
      before { get new_admin_cohort_course_path(cohort) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#create" do
      before { post admin_cohort_courses_path(cohort), params: valid_params }

      it_behaves_like "inaccessible to normal admins"
    end
  end

  context "when not logged in" do
    describe "#show" do
      before { get admin_cohort_course_path(cohort, course_cohort.course) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#new" do
      before { get new_admin_cohort_course_path(cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post admin_cohort_courses_path(cohort), params: valid_params }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
