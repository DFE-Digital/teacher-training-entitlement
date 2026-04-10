require "rails_helper"

RSpec.describe Notification do
  let(:application) { create(:application) }

  it "can be created with any event name" do
    event = build(:notification, application:, event: "application_submitted")
    expect(event).to be_valid
  end

  describe "#recipient=" do
    it "stores recipient in metadata" do
      notification = described_class.new(recipient: "test@example.com")
      expect(notification.metadata["recipient"]).to eq("test@example.com")
    end
  end

  describe "#cohort_id=" do
    it "stores cohort_id in metadata" do
      notification = described_class.new(cohort_id: 123)
      expect(notification.metadata["cohort_id"]).to eq(123)
    end
  end
end
