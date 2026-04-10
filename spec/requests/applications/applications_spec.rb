require "rails_helper"

RSpec.describe "Applications::ApplicationsController", type: :request do
  let(:pending_application) { create(:application, :pending) }
  let!(:superceded_application) { create(:application, :superceded, user: pending_application.user) }

  let(:user) { pending_application.user }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /applications" do
    context "when the user has a single not superceded application" do
      it do
        get "/applications"

        expect(response).to redirect_to(application_path(pending_application.ecf_id))
      end
    end

    context "when the user has multiple applications" do
      let!(:completed_application) { create(:application, :completed, user: pending_application.user) }

      it do
        get "/applications"

        aggregate_failures do
          expect(response).to render_template(:index)
          expect(response).to be_successful
          expect(assigns[:applications]).to include(pending_application)
          expect(assigns[:applications]).to include(completed_application)
          expect(assigns[:applications]).not_to include(superceded_application)
        end
      end
    end
  end

  describe "GET /applications/:ecf_id" do
    context "when the user visits a pending application" do
      it do
        get "/applications/#{pending_application.ecf_id}"

        expect(response).to be_successful
      end
    end

    context "when the user visits a superceded application" do
      it "redirects you back to the applications index" do
        get "/applications/#{superceded_application.ecf_id}"

        expect(response).to redirect_to(applications_path)
      end
    end

    context "when the user visits an application which doesn't exist" do
      it "redirects you back to aaa" do
        get "/applications/does-not-exist"

        expect(response).to redirect_to(applications_path)
      end
    end
  end
end
