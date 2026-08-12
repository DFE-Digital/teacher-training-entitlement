require "rails_helper"

RSpec.describe Admin::CourseCohortProvidersController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:course) { create(:course) }
  let(:lead_provider) { create(:lead_provider) }
  let!(:course_cohort) { create(:course_cohort, course:, lead_provider:) }

  before { sign_in_as_admin(super_admin:) }

  context "when logged in as super admin" do
    let(:super_admin) { true }

    describe "#edit" do
      let(:course_cohort_provider) { course_cohort.course_cohort_providers.find_by!(lead_provider:) }

      before { get edit_admin_course_course_cohort_provider_path(course, course_cohort_provider) }

      it { expect(response).to have_http_status(:success) }

      it "shows the provider" do
        expect(response.body).to include(ERB::Util.html_escape(lead_provider.name))
      end

      context "when contract year defaults exist" do
        before do
          create(
            :contract_year,
            :generic,
            lead_provider:,
            course:,
            academic_year: course_cohort.academic_year,
            recruitment_target: 300,
            teacher_funding: 650,
          )

          get edit_admin_course_course_cohort_provider_path(course, course_cohort_provider)
        end

        it "shows the contract year defaults as context" do
          expect(response.body).to include("Contract year defaults")
          expect(response.body).to include("300")
          expect(response.body).to include("£650.00")
          expect(response.body).to include("Optional course cohort override.")
        end
      end
    end

    describe "#update" do
      let(:course_cohort_provider) { course_cohort.course_cohort_providers.find_by!(lead_provider:) }

      it "updates the recruitment target and teacher funding" do
        patch admin_course_course_cohort_provider_path(course, course_cohort_provider),
              params: {
                course_cohort_provider: { recruitment_target: 42, teacher_funding: 123.45 },
              }

        expect(response).to redirect_to(admin_cohort_course_path(course_cohort.cohort, course))
        expect(course_cohort_provider.reload.recruitment_target).to eq(42)
        expect(course_cohort_provider.teacher_funding).to eq(123.45)
      end
    end
  end

  context "when logged in as normal admin" do
    let(:super_admin) { false }

    describe "#edit" do
      let(:course_cohort_provider) { course_cohort.course_cohort_providers.find_by!(lead_provider:) }

      before { get edit_admin_course_course_cohort_provider_path(course, course_cohort_provider) }

      it "redirects to the course page" do
        expect(response).to redirect_to(admin_cohort_course_path(course_cohort.cohort, course))
        expect(flash[:error]).to match(/You must be a super admin to change course cohort providers/i)
      end
    end
  end
end
