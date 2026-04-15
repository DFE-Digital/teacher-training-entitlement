require "rails_helper"

RSpec.describe ApplicationEvent do
  let(:application) { create(:application) }

  subject(:application_event) { create(:application_event, application:) }

  describe "relationships" do
    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:lead_provider).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:event) }

    it "validates event format" do
      event = build(:application_event, event: "invalid_event")
      expect(event).not_to be_valid
      expect(event.errors[:event]).to include("is invalid")
    end

    it "accepts StateChange:: events" do
      event = build(:application_event, event: "StateChange::Application::ACCEPTED")
      expect(event).to be_valid
    end

    it "accepts Notification:: events" do
      event = build(:application_event, event: "Notification::ApplicationSubmitted")
      expect(event).to be_valid
    end
  end

  describe "#status" do
    it "returns the status for state change events" do
      event = build(:application_event, event: "StateChange::Application::ACCEPTED")
      expect(event.status).to eq("accepted")
    end

    it "returns nil for notification events" do
      event = build(:application_event, event: "Notification::ApplicationSubmitted")
      expect(event.status).to be_nil
    end
  end

  describe "#reason" do
    it "returns the reason from metadata" do
      event = build(:application_event, metadata: { "reason" => "bereavement" })
      expect(event.reason).to eq("bereavement")
    end

    it "returns nil when no reason in metadata" do
      event = build(:application_event, metadata: {})
      expect(event.reason).to be_nil
    end
  end
end
