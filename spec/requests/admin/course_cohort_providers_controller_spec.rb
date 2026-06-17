require "rails_helper"

RSpec.describe Admin::CourseCohortProvidersController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:course) { create(:course) }
  let(:lead_provider) { create(:lead_provider) }
  let!(:course_cohort) { create(:course_cohort, course:, lead_provider:) }

  before { sign_in_as_admin(super_admin:) }

  context "when logged in as super admin" do
    let(:super_admin) { true }

    describe "#show" do
      before { get admin_course_course_cohort_provider_path(course, course_cohort) }

      it { expect(response).to have_http_status(:success) }
    end

    describe "#update" do
      let!(:new_lead_provider) { create(:lead_provider) }

      it "updates the providers for the course cohort" do
        patch admin_course_course_cohort_provider_path(course, course_cohort),
              params: {
                course_cohort: { lead_provider_ids: [new_lead_provider.id] },
              }

        expect(response).to redirect_to(admin_cohort_course_path(course_cohort.cohort, course))
        expect(course_cohort.lead_providers.reload).to contain_exactly(new_lead_provider)
      end
    end
  end

  context "when logged in as normal admin" do
    let(:super_admin) { false }

    describe "#show" do
      before { get admin_course_course_cohort_provider_path(course, course_cohort) }

      it "redirects to the course page" do
        expect(response).to redirect_to(admin_cohort_course_path(course_cohort.cohort, course))
        expect(flash[:error]).to match(/You must be a super admin to change course cohort providers/i)
      end
    end
  end
end
