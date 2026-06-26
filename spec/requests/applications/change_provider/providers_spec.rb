require "rails_helper"

RSpec.describe "Applications::ChangeProvider::Providers", type: :request do
  let(:application) { create(:application) }
  let(:another_provider) { create(:lead_provider) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/providers" }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })

    create(:cohort_provider, lead_provider: another_provider,
                             cohort: application.cohort)
  end

  describe "GET /applications/:application_id/change-provider/providers" do
    it "renders the index template" do
      get url
      expect(response).to render_template(:index)
    end

    context "when application is not eligible for change provider" do
      let(:application) { create(:application, :started) }

      it "redirects to the application page" do
        get url
        expect(response).to redirect_to(application_path(application.ecf_id))
      end
    end
  end

  describe "POST /applications/:application_id/change-provider/providers" do
    context "with blank provider_id" do
      it "redirects to providers path and shows an error" do
        post url, params: { form: { provider_id: nil } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:index)
        expect(assigns[:form]).not_to be_nil
        expect(assigns[:form].errors[:provider_id]).to eq([I18n.t("applications.change_provider.providers.form.blank")])
      end
    end

    context "with same provider_id" do
      it "redirects to providers path and shows an error" do
        post url, params: { form: { provider_id: application.lead_provider.id } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:index)
        expect(assigns[:form]).not_to be_nil
        expect(assigns[:form].errors[:provider_id]).to eq([I18n.t("applications.change_provider.providers.form.different_provider")])
      end
    end

    context "with valid provider_id" do
      it "redirects to check answers path" do
        post url, params: { form: { provider_id: another_provider.id } }
        expect(response).to redirect_to(application_change_provider_check_answers_path(application.ecf_id))
      end
    end
  end
end
