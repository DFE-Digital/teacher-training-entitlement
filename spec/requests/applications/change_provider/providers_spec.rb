require "rails_helper"

RSpec.describe "Applications::ChangeProvider::Providers", type: :request do
  let(:application) { create(:application) }
  let(:another_provider) { create(:lead_provider) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/choose-provider" }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })

    create(:course_cohort, lead_provider: another_provider,
                           course: application.course,
                           cohort: application.cohort)
  end

  describe "GET /applications/:application_ecf_id/change-provider/choose-provider" do
    it "renders the index template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_choose_provider)
    end

    context "when application is not eligible for change provider" do
      let(:application) { create(:application, :started) }

      it "redirects to the exit page" do
        get url
        expect(response).to redirect_to(application_path(application.ecf_id))
      end
    end
  end

  describe "PATCH /applications/:application_id/change-provider/choose-provider" do
    context "with blank provider_id" do
      it "redirects to providers path and shows an error" do
        patch url, params: { "choose-provider" => { provider_id: nil } }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_choose_provider)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:provider_id]).to eq([I18n.t("applications.change_provider.providers.form.blank")])
      end
    end

    context "with same provider_id" do
      it "redirects to providers path and shows an error" do
        patch url, params: { "choose-provider" => { provider_id: application.lead_provider.id } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_choose_provider)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:provider_id]).to eq([I18n.t("applications.change_provider.providers.form.different_provider")])
      end
    end

    context "with an unavailable provider_id" do
      let(:unavailable_provider) { create(:lead_provider) }

      it "renders providers path and shows an error" do
        patch url, params: { "choose-provider" => { provider_id: unavailable_provider.id } }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_choose_provider)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:provider_id]).to eq([I18n.t("applications.change_provider.providers.form.invalid")])
      end
    end

    context "with valid provider_id" do
      it "redirects to check answers path" do
        patch url, params: { "choose-provider" => { provider_id: another_provider.id } }
        expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "check-answers"))
      end
    end
  end
end
