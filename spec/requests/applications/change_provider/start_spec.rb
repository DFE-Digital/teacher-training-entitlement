require "rails_helper"

RSpec.describe "Applications::ChangeProvider::Start", type: :request do
  let(:application) { create(:application) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/start" }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /applications/:application_id/change-provider/start" do
    it "renders the index template" do
      get url
      expect(response).to render_template(:index)
    end
  end

  describe "POST /applications/:application_id/change-provider/start" do
    context "with valid confirmation" do
      it "redirects to providers path" do
        post url, params: { form: { confirmation: "1" } }
        expect(response).to redirect_to(application_change_provider_providers_path(application.ecf_id))
      end
    end

    context "without confirmation" do
      it "redirects to user registration path" do
        post url, params: { form: { confirmation: "0" } }
        expect(response).to redirect_to(accounts_user_registration_path(application))
      end
    end

    context "with invalid form" do
      it "renders index with unprocessable entity status" do
        post url, params: { form: { confirmation: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:index)
        expect(assigns[:form]).not_to be_nil
        expect(assigns[:form].errors[:confirmation]).to eq([I18n.t("applications.change_provider.start.form.blank")])
      end
    end

    context "when application is not eligible for change provider" do
      let(:application) { create(:application, :accepted) }

      it "redirects to accounts page with alert" do
        post url, params: { form: { confirmation: "1" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:index)
        expect(assigns[:form]).not_to be_nil
        expect(assigns[:form].errors[:cannot_change_provider]).to eq([I18n.t("applications.change_provider.start.form.cannot_change_provider")])
      end
    end
  end
end
