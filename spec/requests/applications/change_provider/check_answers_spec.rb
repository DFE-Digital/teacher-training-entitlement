require "rails_helper"

RSpec.describe "Applications::ChangeProvider::CheckAnswers", type: :request do
  let(:application) { create(:application) }
  let(:another_provider) { create(:lead_provider) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/check-answers" }
  let(:session) { { user_id: user.id, change_provider: { provider_id: session_provider_id } } }
  let(:session_provider_id) { nil }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)

    create(:course_cohort, lead_provider: another_provider,
                           course: application.course,
                           cohort: application.cohort)
  end

  describe "GET /applications/:application_id/change-provider/check-answers" do
    context "with valid provider_id in the session" do
      let(:session_provider_id) { another_provider.id }

      it "renders the index template" do
        get url
        expect(response).to render_template(:index)
      end
    end

    context "with missing provider_id in the session" do
      let(:session_provider_id) { nil }

      it "redirects back to the start page" do
        get url
        expect(response).to redirect_to(application_change_provider_start_index_path(application.ecf_id))
      end
    end
  end

  describe "POST /applications/:application_id/change-provider/check-answers" do
    context "with valid provider_id in the session" do
      let(:session_provider_id) { another_provider.id }

      it "updates the application's lead provider and redirects to user registrations path" do
        post url
        expect(response).to redirect_to(application_path(application.ecf_id))
        expect(application.reload.lead_provider_id).to eq(session_provider_id)
        expect(flash[:notice][:title]).to eq(I18n.t("applications.change_provider.check_answers.success.title"))
        expect(flash[:notice][:message]).to eq(I18n.t("applications.change_provider.check_answers.success.message"))
      end
    end

    context "with missing provider_id in the session" do
      let(:session_provider_id) { nil }

      it "redirects back to the start page" do
        post url
        expect(response).to redirect_to(application_change_provider_start_index_path(application.ecf_id))
      end
    end
  end
end
