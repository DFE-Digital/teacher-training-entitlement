require "rails_helper"

RSpec.describe SessionsController do
  include Devise::Test::ControllerHelpers
  include Helpers::JourneyHelper

  describe "#extend_session" do
    context "when a user is signed in" do
      let(:user) { create(:user) }

      before do
        session[:user_id] = user.id
        session[:last_activity_at] = 20.minutes.ago
      end

      it "updates last_activity_at and returns ok" do
        get :extend_session

        expect(response).to have_http_status(:ok)
        expect(session[:last_activity_at]).to be_within(1.second).of(Time.current)
      end
    end

    context "when no user is signed in" do
      it "returns unauthorized" do
        get :extend_session

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "#destroy" do
    it "signs out all scopes" do
      expect(controller).to receive(:sign_out_all_scopes)
      get :destroy
    end

    context "with an OIDC session" do
      it "redirects to the OIDC provider's logout endpoint" do
        session[:id_token] = "test-id-token"

        get :destroy

        expect(response.location).to include("/oauth2/logout")
        expect(response.location).to include("id_token_hint=test-id-token")
      end
    end

    context "without an OIDC session" do
      it "redirects to root" do
        get :destroy

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "#destroy_admin" do
    it "signs out all scopes and redirects to admin" do
      expect(controller).to receive(:sign_out_all_scopes)

      get :destroy_admin

      expect(response).to redirect_to("/admin")
    end
  end
end
