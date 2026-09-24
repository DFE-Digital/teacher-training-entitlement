require "rails_helper"

RSpec.describe "One Login redirect", type: :request do
  describe "POST /one-login" do
    it "sends a started event and redirects to Teacher Auth" do
      event = instance_double(Analytics::DfeCustomEvents)
      allow(Analytics::DfeCustomEvents).to receive(:new).with(
        type: :one_login_started,
        request: an_instance_of(ActionDispatch::Request),
      ).and_return(event)
      expect(event).to receive(:send_event)

      post one_login_redirect_path

      expect(response).to redirect_to(user_teacher_auth_omniauth_authorize_path)
      expect(response).to have_http_status(:temporary_redirect)
    end
  end
end
