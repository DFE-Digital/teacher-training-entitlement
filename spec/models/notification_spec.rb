require "rails_helper"

RSpec.describe Notification do
  let(:application) { create(:application) }

  it "can be created with any event name" do
    event = build(:notification, application:, event: "application_submitted")
    expect(event).to be_valid
  end
end
