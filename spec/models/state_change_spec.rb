require "rails_helper"

RSpec.describe StateChange do
  let(:application) { create(:application) }

  describe ".expired_deferrals" do
    it "returns application_ids where most recent deferral exceeds threshold" do
      deferred = create(:application, :deferred)
      deferred.state_changes.last.update!(created_at: 15.months.ago)

      expect(described_class.expired_deferrals(months_ago: 14).pluck(:application_id)).to eq([deferred.id])
    end
  end

  describe "validations" do
    it "validates event is a valid status" do
      event = build(:state_change, application:, event: "invalid_status")
      expect(event).not_to be_valid
      expect(event.errors[:event]).to include("is not included in the list")
    end

    it "accepts valid status events" do
      Application::STATUSES.each do |status|
        event = build(:state_change, application:, event: status)
        expect(event).to be_valid
      end
    end
  end

  describe "#status" do
    it "returns the event as the status" do
      event = build(:state_change, application:, event: Application::ACCEPTED)
      expect(event.status).to eq("accepted")
    end
  end

  describe "#reason" do
    it "returns the reason from metadata" do
      event = build(:state_change, metadata: { "reason" => "bereavement" })
      expect(event.reason).to eq("bereavement")
    end

    it "returns nil when no reason in metadata" do
      event = build(:state_change, metadata: {})
      expect(event.reason).to be_nil
    end
  end
end
