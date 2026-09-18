require "rails_helper"

RSpec.describe APITests::CompletedDeclaration, type: :model do
  subject(:service) { described_class.new(application:, has_passed:, delivery_partner:) }

  let!(:application) { create(:application, :started, lead_provider:, course_cohort:) }
  let(:course_cohort) { create(:course_cohort, training_starts_at: 1.day.ago.to_date) }
  let(:lead_provider) { create(:lead_provider, delivery_partner: default_delivery_partner) }
  let(:default_delivery_partner) { create(:delivery_partner) }
  let(:delivery_partner) { create(:delivery_partner) }
  let(:has_passed) { "true" }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
  let(:completed_milestone) do
    application.course.milestones.find_or_initialize_by(declaration_type: Milestone::COMPLETED).tap do |milestone|
      milestone.update!(acceptance_window_start_offset: 0, acceptance_window_end_offset: 1)
    end
  end
  let(:declaration_date) { completed_milestone.acceptance_window_start_date_for(training_starts_at: application.training_starts_at).in_time_zone("UTC") }

  let(:expected_body) do
    {
      data: {
        attributes: {
          declaration_date: declaration_date.utc.iso8601,
          delivery_partner_id: delivery_partner.ecf_id,
          has_passed: true,
        },
      },
    }.to_json
  end

  let(:expected_url) do
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{Rails.application.routes.url_helpers.completed_declaration_api_v1_application_path(application.ecf_id)}"
  end

  before do
    completed_milestone if application
    stub_const("LEAD_PROVIDER_CONFIG", lead_provider.name => { token: "test-token" }) if lead_provider
    allow(HTTParty).to receive(:post).and_return(api_response)
  end

  describe "#call" do
    it "posts a completed declaration request" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:post).with(
        expected_url,
        body: expected_body,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when has_passed is false" do
      let(:has_passed) { "no" }

      let(:expected_body) do
        {
          data: {
            attributes: {
              declaration_date: declaration_date.utc.iso8601,
              delivery_partner_id: delivery_partner.ecf_id,
              has_passed: false,
            },
          },
        }.to_json
      end

      it "sends false in the payload" do
        service.call

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a delivery partner is not provided" do
      let(:delivery_partner) { nil }

      let(:expected_body) do
        {
          data: {
            attributes: {
              declaration_date: declaration_date.utc.iso8601,
              delivery_partner_id: default_delivery_partner.ecf_id,
              has_passed: true,
            },
          },
        }.to_json
      end

      it "uses the lead provider's first delivery partner" do
        service.call

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when an application is not provided" do
      subject(:service) { described_class.new(has_passed:, delivery_partner:) }

      let!(:application) { create(:application, :started, lead_provider:, course_cohort:) }

      it "uses the most recent started application" do
        service.call

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a started application cannot be found" do
      subject(:service) { described_class.new(has_passed:, delivery_partner:) }

      let(:application) { nil }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[StartedDeclaration] Could not find a started application")
      end
    end
  end
end
