require "rails_helper"

RSpec.describe "One Login redirect", type: :request do
  describe "POST /one-login" do
    it "sends a started event and redirects to Teacher Auth" do
      expect(StreamAnalyticsEventToBigQueryJob).to receive(:send_event).with(
        type: :one_login_started,
        request: an_instance_of(ActionDispatch::Request),
      )

      post one_login_redirect_path

      expect(response).to redirect_to(user_teacher_auth_omniauth_authorize_path)
      expect(response).to have_http_status(:temporary_redirect)
    end
  end
end
