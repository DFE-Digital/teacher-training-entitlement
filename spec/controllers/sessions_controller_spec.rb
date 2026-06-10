require "rails_helper"

RSpec.describe SessionsController do
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

  context "when a user is signed in" do
    before do
      allow(controller).to receive(:current_user).and_return(create(:user))
    end

    it "redirects to the external OIDC provider's signout endpoint" do
      expect(controller).to receive(:sign_out_all_scopes)

      id_token = "test-id-token"
      session[:id_token] = id_token

      post_logout_uri = "http://test.host/sign-out"
      expected_redirect_url = "https://teacher-auth.example.com:443/oauth2/logout?id_token_hint=#{id_token}&post_logout_redirect_uri=#{CGI.escape(post_logout_uri)}"

      get :destroy

      expect(response).to redirect_to(expected_redirect_url)
    end
  end

  context "when an admin is signed in" do
    before do
      allow(controller).to receive(:current_admin).and_return(create(:admin))
    end

    it "redirects to admin path" do
      expect(controller).to receive(:sign_out_all_scopes)

      get :destroy

      expect(response).to redirect_to("/admin")
    end
  end

  context "when no user is signed in (callback from provider)" do
    it "redirects to root" do
      expect(controller).to receive(:sign_out_all_scopes)

      get :destroy

      expect(response).to redirect_to(root_path)
    end
  end
end
