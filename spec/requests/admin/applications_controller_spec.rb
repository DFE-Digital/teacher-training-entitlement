require "rails_helper"

RSpec.describe Admin::ApplicationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "/admin/applications" do
    let!(:pending_application) { create(:application, :pending) }
    let!(:superceded_application) { create(:application, :superceded) }

    it do
      get admin_applications_path

      expect(assigns[:applications]).to eq([pending_application, superceded_application])
      expect(response).to have_http_status(:ok)
    end

    context "when filtering on status" do
      context "when filtering for pending applications" do
        it do
          get admin_applications_path, params: { status: Application::PENDING }

          expect(assigns[:applications]).to eq([pending_application])
          expect(response).to have_http_status(:ok)
        end
      end

      context "when filtering for superceded applications" do
        it do
          get admin_applications_path, params: { status: Application::SUPERCEDED }

          expect(assigns[:applications]).to eq([superceded_application])
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "/admin/applications/{id}" do
    context "when loading a superceded application" do
      let(:application) { create(:application, :superceded, superceding_application: create(:application, :pending)) }

      it do
        get admin_application_path(application.id)

        expect(assigns[:application]).to eq(application)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when loading a pending application" do
      let(:application) { create(:application, :pending) }

      it do
        get admin_application_path(application.id)

        expect(assigns[:application]).to eq(application)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the application cannot be found", :exceptions_app do
      it do
        get admin_application_path(-1)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
