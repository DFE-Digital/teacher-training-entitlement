require "rails_helper"

RSpec.describe "Pages", type: :request do
  it "returns not found for non-HTML requests" do
    get "/cookies.json"

    expect(response).to have_http_status(:not_found)
  end

  it "succeeds for HTML requests" do
    get "/cookies"

    expect(response).to have_http_status(:ok)
  end
end
