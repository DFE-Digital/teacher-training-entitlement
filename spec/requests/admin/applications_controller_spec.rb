require "rails_helper"

RSpec.describe Admin::ApplicationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "/admin/applications" do
    let!(:pending_application) { create(:application, :pending) }

    it "renders the applications index" do
      get admin_applications_path

      expect(assigns[:applications]).to include(pending_application)
      expect(response).to have_http_status(:ok)
    end

    it "filters applications by status" do
      accepted_application = create(:application, :accepted)

      get admin_applications_path, params: { status: Application::ACCEPTED }

      expect(assigns[:applications]).to eq([accepted_application])
      expect(response).to have_http_status(:ok)
    end

    it "filters applications by work setting" do
      school_application = create(:application, work_setting: "a_school")

      get admin_applications_path, params: { work_setting: "a_school" }

      expect(assigns[:applications]).to eq([school_application])
      expect(response).to have_http_status(:ok)
    end
  end

  describe "/admin/applications/{id}" do
    context "when loading a pending application" do
      let(:application) { create(:application, :pending) }

      it do
        get admin_application_path(application.ecf_id)

        expect(assigns[:application]).to eq(application)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the application cannot be found", :exceptions_app do
      it do
        get admin_application_path(SecureRandom.uuid)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
