require "rails_helper"

RSpec.describe StreamAnalyticsEventToBigQueryJob, type: :job do
  describe ".send_event" do
    subject(:enqueue_event) { described_class.send_event(type:, request:, user:, data:) }

    let(:analytics_event) { instance_double(DfE::Analytics::Event, as_json: event_payload) }
    let(:request) { nil }
    let(:user) { nil }

    before do
      allow(DfE::Analytics::Event).to receive(:new).and_return(analytics_event)
      allow(analytics_event).to receive(:with_type).with(type).and_return(analytics_event)
      allow(analytics_event).to receive(:with_data).with(data:).and_return(analytics_event)
    end

    context "when streaming a version event" do
      let(:type) { :version }
      let(:user) { "Admin 1" }
      let(:event_payload) { { "event_type" => "version" } }
      let(:data) do
        {
          "whatever" => "whatever",
          "object_changes" => %w[something something_else],
        }
      end

      before do
        allow(analytics_event).to receive(:with_namespace).with("npq").and_return(analytics_event)
        allow(analytics_event).to receive(:with_user).with(user).and_return(analytics_event)
      end

      it "builds and enqueues a DfE Analytics version event" do
        expect {
          enqueue_event
        }.to have_enqueued_job(described_class).with(event_payload)
      end
    end

    context "when streaming a custom request event" do
      let(:type) { :one_login_completed }
      let(:request) { instance_double(ActionDispatch::Request) }
      let(:user) { build_stubbed(:user, id: 123) }
      let(:data) { { error_type: "callback_error" } }
      let(:event_payload) { { "event_type" => "one_login_completed" } }

      before do
        allow(analytics_event).to receive(:with_namespace).with("tte").and_return(analytics_event)
        allow(analytics_event).to receive(:with_request_details).with(request).and_return(analytics_event)
        allow(analytics_event).to receive(:with_user).with(user).and_return(analytics_event)
      end

      it "builds and enqueues a custom DfE Analytics event" do
        expect {
          enqueue_event
        }.to have_enqueued_job(described_class).with(event_payload)
      end
    end
  end

  describe "#perform" do
    subject(:perform) { described_class.perform_now(event_payload) }

    let(:event_payload) { { "event_type" => "one_login_completed" } }

    it "sends the analytics event" do
      expect(DfE::Analytics::SendEvents).to receive(:do).with([event_payload])

      perform
    end
  end
end
