require "rails_helper"

RSpec.describe "Applications::ChangeProvider::Start", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/start" }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /applications/:application_ecf_id/change-provider/start" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_start)
    end

    context "when application is not eligible for change provider" do
      let(:application) { create(:application, :started) }

      it "redirects to the application page" do
        get url
        expect(response).to redirect_to(application_path(application.ecf_id))
      end
    end
  end

  describe "PATCH /applications/:application_ecf_id/change-provider/start" do
    context "with valid confirmation" do
      it "redirects to providers path" do
        patch url, params: { start: { confirmation: "1" } }
        expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "choose-provider"))
      end
    end

    context "without confirmation" do
      it "redirects to user registration path" do
        patch url, params: { start: { confirmation: "0" } }
        expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "exit"))
      end
    end

    context "with invalid form" do
      it "renders show/_start agan" do
        patch url, params: { start: { confirmation: nil } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_start)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:confirmation]).to eq([I18n.t("applications.change_provider.start.application_pending.form.blank")])
      end
    end

    context "when application is not eligible for change provider" do
      let(:application) { create(:application, :started) }

      it "redirects to accounts page with alert" do
        patch url, params: { start: { confirmation: "1" } }
        expect(response).to have_http_status(:ok)
        expect(assigns[:step].errors[:cannot_change_provider]).to eq([I18n.t("applications.change_provider.start.form.cannot_change_provider")])
      end
    end
  end
end
