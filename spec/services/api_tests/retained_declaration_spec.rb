require "rails_helper"

RSpec.describe APITests::RetainedDeclaration, type: :model do
  subject(:service) do
    described_class.new(
      application:,
      declaration_type:,
      delivery_partner:,
    )
  end

  let!(:application) { create(:application, :started, lead_provider:, course_cohort:) }
  let(:course_cohort) { create(:course_cohort, training_starts_at: 1.day.ago.to_date) }
  let(:lead_provider) { create(:lead_provider, delivery_partner: default_delivery_partner) }
  let(:default_delivery_partner) { create(:delivery_partner) }
  let(:delivery_partner) { create(:delivery_partner) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
  let(:milestone) do
    create(
      :milestone,
      course: application.course,
      declaration_type:,
      acceptance_window_start_offset: 1,
      acceptance_window_end_offset: 2,
    )
  end
  let(:declaration_date) do
    milestone.acceptance_window_start_date_for(training_starts_at: application.training_starts_at).in_time_zone("UTC")
  end
  let(:expected_body) do
    {
      data: {
        attributes: {
          declaration_date: declaration_date.utc.iso8601,
          delivery_partner_id: delivery_partner.ecf_id,
        },
      },
    }.to_json
  end
  let(:expected_url) do
    path = Rails.application.routes.url_helpers.declaration_api_v1_application_path(application.ecf_id, declaration_type:)
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{path}"
  end

  before do
    milestone if application
    stub_const("LEAD_PROVIDER_CONFIG", lead_provider.name => { token: "test-token" }) if lead_provider
    allow(HTTParty).to receive(:post).and_return(api_response)
  end

  shared_examples "a retained declaration request" do
    it "posts the retained declaration request" do
      expect(service.call).to eq(api_response)

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

  context "with retained-1" do
    let(:declaration_type) { Milestone::RETAINED_1 }

    it_behaves_like "a retained declaration request"
  end

  context "with retained-2" do
    let(:declaration_type) { Milestone::RETAINED_2 }

    it_behaves_like "a retained declaration request"
  end

  context "when a delivery partner is not provided" do
    let(:declaration_type) { Milestone::RETAINED_1 }
    let(:delivery_partner) { nil }
    let(:expected_body) do
      {
        data: {
          attributes: {
            declaration_date: declaration_date.utc.iso8601,
            delivery_partner_id: default_delivery_partner.ecf_id,
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
    subject(:service) { described_class.new(declaration_type:, delivery_partner:) }

    let(:declaration_type) { Milestone::RETAINED_1 }

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
    subject(:service) { described_class.new(declaration_type:, delivery_partner:) }

    let(:application) { nil }
    let(:declaration_type) { Milestone::RETAINED_1 }

    it "raises an error" do
      expect { service.call }
        .to raise_error(RuntimeError, "[RetainedDeclaration] Could not find a started application")
    end
  end
end
