require "rails_helper"

RSpec.describe "Reception Registrations / Choose Your Provider", type: :request do
  let(:user) { create(:user) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { Course.reception || create(:course, :tte_early_years, display: true) }
  let(:url) { "/reception-registration/choose-your-provider" }
  let(:registration_session) { { confirmation: "yes" } }
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    course_cohort = course.course_cohorts.find_by(cohort: Cohort.current) || create(:course_cohort, course:, cohort: Cohort.current)
    create(:course_cohort_provider, course_cohort:, lead_provider:) unless course_cohort.course_cohort_providers.exists?(lead_provider:)

    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/choose-your-provider" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_choose_your_provider)
    end
  end

  describe "PATCH /reception-registration/choose-your-provider" do
    context "with valid provider" do
      it "redirects to choose school path" do
        patch url, params: { "choose-your-provider" => { lead_provider_id: lead_provider.id } }
        expect(response).to redirect_to(reception_registration_path("teacher-catchment"))
      end
    end

    context "with invalid form" do
      it "renders form again" do
        patch url, params: { "choose-your-provider" => { lead_provider_id: nil } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_choose_your_provider)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:lead_provider_id]).to eq(["can't be blank"])
      end
    end
  end
end
