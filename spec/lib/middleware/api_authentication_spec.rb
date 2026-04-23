require "rails_helper"
require "middleware/api_authentication"

RSpec.describe Middleware::ApiAuthentication, type: :request do
  include Rails.application.routes.url_helpers

  let(:captured_env) { {} }
  let(:app) do
    proc do |env|
      captured_env.merge!(env)
      [200, {}, []]
    end
  end

  let(:middleware) { described_class.new(app) }
  let(:request) { Rack::MockRequest.new(middleware) }
  let(:raw_token) { "lp-token" }
  let!(:api_token) { create(:api_token, raw_token:, last_used_at: nil) }
  let(:lead_provider) { api_token.lead_provider }

  subject(:response) { request.get(path, "HTTP_AUTHORIZATION" => "Bearer #{raw_token}") }

  describe "API requests" do
    let(:path) { api_v1_applications_path }

    it "sets current_lead_provider in env" do
      response
      expect(captured_env["current_lead_provider"]).to eq(lead_provider)
    end

    it "updates api token last_used_at" do
      expect { response }.to change { api_token.reload.last_used_at }.from(nil)
    end
  end

  describe "non API requests" do
    let(:path) { root_path }

    it "does not set current_lead_provider" do
      response
      expect(captured_env["current_lead_provider"]).to be_nil
    end
  end

  # rubocop:disable Layout/HashAlignment
  {
    "/api/v1/applications"        => true,
    "/api/v2/applications"        => true,
    "/api/v10/some/nested/path"   => true,
    "/api/v1"                     => true,
    "/api/v1/"                    => true,
    "///api/v1/"                  => true,
    "/api/v1//applications"       => true,
    "/"                           => false,
    "/admin/dashboard"            => false,
    "/api/applications"           => false,
    "/not-api/v1/applications"    => false,
    "/v1/applications"            => false,
    ""                            => false,
  }.each do |test_path, expected|
    describe "#api_path? for #{test_path}" do
      let(:path) { test_path }

      it "returns #{expected} for '#{test_path}'" do
        response
        expect(captured_env.key?("current_lead_provider")).to be expected
      end
    end
    # rubocop:enable Layout/HashAlignment
  end
end
