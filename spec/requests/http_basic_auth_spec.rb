require "rails_helper"

RSpec.describe "HTTP Basic Auth" do
  before do
    allow(Rails.env).to receive(:staging?).and_return(true)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("HTTP_BASIC_AUTH_USER_PASS", nil).and_return("admin:secret")
  end

  it "returns 401 without credentials" do
    get root_path
    expect(response).to have_http_status(:unauthorized)
  end

  it "allows access with correct credentials" do
    get root_path, headers: {
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret"),
    }
    expect(response).to have_http_status(:success)
  end
end
