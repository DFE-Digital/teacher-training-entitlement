require "rails_helper"
require "middleware/sentry_lead_provider_context"

RSpec.describe Middleware::SentryLeadProviderContext do
  include Rails.application.routes.url_helpers

  let(:app) { proc { [200, {}, []] } }
  let(:middleware) { described_class.new(app) }
  let(:request) { Rack::MockRequest.new(middleware) }
  let(:lead_provider) { build_stubbed(:lead_provider) }
  let(:sentry_scope) { instance_double(Sentry::Scope) }

  before do
    allow(sentry_scope).to receive(:set_tag)
    allow(sentry_scope).to receive(:set_user)
    allow(sentry_scope).to receive(:set_context)
    allow(Sentry).to receive(:configure_scope).and_yield(sentry_scope)
    response
  end

  describe "API requests" do
    let(:path) { api_v1_applications_path }

    context "when current_lead_provider is set in env" do
      subject(:response) { request.get(path, "current_lead_provider" => lead_provider) }

      it "tags sentry with lead_provider_id" do
        expect(sentry_scope).to have_received(:set_tag).with("lead_provider_id", lead_provider.id)
      end

      it "tags sentry with lead_provider_name" do
        expect(sentry_scope).to have_received(:set_tag).with("lead_provider_name", lead_provider.name)
      end

      it "sets sentry user" do
        expect(sentry_scope).to have_received(:set_user).with(id: lead_provider.id, username: lead_provider.name)
      end

      it "sets sentry lead_provider context" do
        expect(sentry_scope).to have_received(:set_context).with("lead_provider", { id: lead_provider.id, name: lead_provider.name })
      end

      it "returns the app response" do
        expect(response.status).to eq(200)
      end
    end

    context "when current_lead_provider is not set in env" do
      subject(:response) { request.get(path) }

      it "does not configure sentry scope" do
        expect(Sentry).not_to have_received(:configure_scope)
      end

      it "returns the app response" do
        expect(response.status).to eq(200)
      end
    end
  end

  describe "non API requests" do
    subject(:response) { request.get("/some/other/path", "current_lead_provider" => lead_provider) }

    it "does not configure sentry scope" do
      response
      expect(Sentry).not_to have_received(:configure_scope)
    end

    it "returns the app response" do
      expect(response.status).to eq(200)
    end
  end
end
