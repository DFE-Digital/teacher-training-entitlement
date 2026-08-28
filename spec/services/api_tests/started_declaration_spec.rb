require "rails_helper"

RSpec.describe APITests::StartedDeclaration, type: :model do
  subject(:service) { described_class.new(application:, delivery_partner:) }

  let(:application) { create(:application, :accepted, lead_provider:) }
  let(:lead_provider) { create(:lead_provider, delivery_partner: default_delivery_partner) }
  let(:default_delivery_partner) { create(:delivery_partner) }
  let(:delivery_partner) { create(:delivery_partner) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
  let(:started_milestone) { create(:milestone, :started, course_cohort: application.course_cohort) }
  let(:declaration_date) { started_milestone.acceptance_window_start_date.in_time_zone("UTC") }

  let(:expected_body) do
    {
      data: {
        attributes: {
          delivery_partner_id: delivery_partner.ecf_id,
          declaration_date: declaration_date.utc.iso8601,
        },
      },
    }.to_json
  end

  let(:expected_url) do
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{expected_path}"
  end

  let(:expected_path) do
    Rails.application.routes.url_helpers.started_declaration_api_v1_application_path(application.ecf_id)
  end

  before do
    started_milestone if application
    stub_const("LEAD_PROVIDER_CONFIG", lead_provider.name => { token: "test-token" }) if lead_provider
    allow(HTTParty).to receive(:post).and_return(api_response)
  end

  describe "#call" do
    it "posts a started declaration request for the application" do
      travel_to(declaration_date) do
        expect(service.call).to eq(api_response)
      end

      expect(HTTParty).to have_received(:post).with(
        expected_url,
        body: expected_body,
        headers: hash_including(
          "Authorization" => "Bearer test-token",
          "Content-Type" => "application/json",
          "X-With-Server-Date" => declaration_date.utc.iso8601,
        ),
      )
    end

    context "when a delivery partner is not provided" do
      let(:delivery_partner) { nil }

      let(:expected_body) do
        {
          data: {
            attributes: {
              delivery_partner_id: default_delivery_partner.ecf_id,
              declaration_date: declaration_date.utc.iso8601,
            },
          },
        }.to_json
      end

      it "uses the lead provider's first delivery partner" do
        travel_to(declaration_date) { service.call }

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including(
            "Authorization" => "Bearer test-token",
            "Content-Type" => "application/json",
            "X-With-Server-Date" => declaration_date.utc.iso8601,
          ),
        )
      end
    end

    context "when an application is not provided" do
      subject(:service) { described_class.new(delivery_partner:) }

      let(:application) { create(:application, :accepted, lead_provider:) }

      it "uses the most recent accepted application" do
        application

        travel_to(declaration_date) { service.call }

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including(
            "Authorization" => "Bearer test-token",
            "Content-Type" => "application/json",
            "X-With-Server-Date" => declaration_date.utc.iso8601,
          ),
        )
      end
    end

    context "when an accepted application cannot be found" do
      subject(:service) { described_class.new(delivery_partner:) }

      let(:application) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[StartedDeclaration] Could not find an accepted application")
      end
    end
  end
end
