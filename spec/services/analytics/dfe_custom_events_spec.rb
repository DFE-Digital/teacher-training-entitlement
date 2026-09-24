require "rails_helper"

RSpec.describe Analytics::DfeCustomEvents do
  subject(:send_event) { described_class.new(type: :one_login_completed, request:, user:).send_event }

  let(:request) { instance_double(ActionDispatch::Request) }
  let(:user) { build_stubbed(:user) }
  let(:analytics_event) { instance_double(DfE::Analytics::Event) }

  before do
    allow(DfE::Analytics::Event).to receive(:new).and_return(analytics_event)
    allow(analytics_event).to receive(:with_type).with(:one_login_completed).and_return(analytics_event)
    allow(analytics_event).to receive(:with_namespace).with("tte").and_return(analytics_event)
    allow(analytics_event).to receive(:with_request_details).with(request).and_return(analytics_event)
    allow(analytics_event).to receive(:with_data).with(data: {}).and_return(analytics_event)
    allow(analytics_event).to receive(:with_user).with(user).and_return(analytics_event)
  end

  it "sends a DfE Analytics event" do
    expect(DfE::Analytics::SendEvents).to receive(:do).with([analytics_event])

    send_event
  end

  it "does not raise if the event cannot be sent" do
    allow(DfE::Analytics::SendEvents).to receive(:do).and_raise(StandardError, "Nope")

    expect { send_event }.not_to raise_error
  end
end
