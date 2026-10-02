require "rails_helper"

RSpec.describe APITests::RevertToPendingApplication, type: :model do
  subject(:service) { described_class.new(application:) }

  let(:application) { create(:application, :accepted, lead_provider:, course_cohort:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :npd_eirt) }
  let(:course_cohort) { create(:course_cohort, course:) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }

  let(:expected_url) do
    "#{ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000")}#{Rails.application.routes.url_helpers.revert_to_pending_api_v1_application_path(application.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_CONFIG", lead_provider.name => { token: "test-token" }) if lead_provider
    allow(HTTParty).to receive(:put).and_return(api_response)
  end

  it "calls the revert to pending endpoint" do
    expect(service.call).to eq(api_response)

    expect(HTTParty).to have_received(:put).with(
      expected_url,
      body: nil,
      headers: hash_including("Authorization" => "Bearer test-token"),
    )
  end

  context "when no application is provided" do
    subject(:service) { described_class.new }

    let(:application) { create(:application, :accepted, lead_provider:, course_cohort:) }

    it "uses the latest accepted application" do
      application
      service.call

      expect(HTTParty).to have_received(:put).with(
        expected_url,
        body: nil,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end
  end

  context "when an application cannot be found" do
    subject(:service) { described_class.new }

    let(:application) { nil }

    it "raises an error" do
      expect { service.call }.to raise_error(RuntimeError, "[RevertToPendingApplication] Could not find an accepted application")
    end
  end
end
