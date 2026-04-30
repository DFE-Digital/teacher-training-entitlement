require "rails_helper"

RSpec.describe APITests::ResumeApplication, type: :model do
  subject(:service) { described_class.new(application:, course_cohort:) }

  let(:application) { create(:application, :deferred, lead_provider:, course_cohort:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course_cohort) { create(:course_cohort, lead_provider:, schedule:) }
  let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }

  let(:expected_body) do
    {
      data: {
        type: "application",
        attributes: {
          schedule_id: course_cohort.ecf_id,
        },
      },
    }.to_json
  end

  let(:expected_url) do
    "http://localhost:3000#{Rails.application.routes.url_helpers.resume_api_v1_application_path(application.ecf_id)}"
  end

  before do
    stub_const("LEAD_PROVIDER_TOKENS", lead_provider.name => "test-token") if lead_provider
    allow(HTTParty).to receive(:put).and_return(api_response)
  end

  describe "#call" do
    it "sends a resume application request" do
      expect(service.call).to eq(api_response)

      expect(HTTParty).to have_received(:put).with(
        expected_url,
        body: expected_body,
        headers: hash_including("Authorization" => "Bearer test-token"),
      )
    end

    context "when a course cohort is not provided" do
      subject(:service) { described_class.new(application:) }

      it "uses the lead provider's last training-live course cohort" do
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when an application is not provided" do
      subject(:service) { described_class.new(course_cohort:) }

      let(:application) { create(:application, :deferred, lead_provider:, course_cohort:) }

      it "uses the most recent deferred application for a provider with a live course cohort" do
        application
        service.call

        expect(HTTParty).to have_received(:put).with(
          expected_url,
          body: expected_body,
          headers: hash_including("Authorization" => "Bearer test-token"),
        )
      end
    end

    context "when a deferred application cannot be found" do
      subject(:service) { described_class.new(course_cohort:) }

      let(:application) { nil }

      before { course_cohort }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "[ResumeApplication] Could not find a deferred application")
      end
    end

    context "when the provider has no live course cohorts" do
      subject(:service) { described_class.new(application:) }

      let(:application) { create(:application, :deferred, lead_provider:, course_cohort:) }
      let(:schedule) { create(:schedule, training_starts_at: 3.days.ago, training_ends_at: 1.day.ago) }

      it "raises an error" do
        expect { service.call }
          .to raise_error(RuntimeError, "Cannot find any live course cohorts for #{lead_provider.name}")
      end
    end
  end
end
