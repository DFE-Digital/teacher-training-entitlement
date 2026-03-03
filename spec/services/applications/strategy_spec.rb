require "rails_helper"

RSpec.describe Applications::Strategy, type: :model do
  subject(:service) { Applications::Strategy.for(application:, training_status:, reason:) }

  let(:application) { build(:application) }
  let(:training_status) { nil }
  let(:reason) { "other" }

  context "when withdrawing an application" do
    let(:training_status) { Applications::Strategy::WITHDRAWN }

    it do
      expect(service).to be_a(Applications::Withdraw)
    end
  end

  context "when resuming an application" do
    let(:training_status) { Applications::Strategy::ACTIVE }

    it do
      expect(service).to be_a(Applications::Resume)
    end
  end

  context "when deferring an application" do
    let(:training_status) { Applications::Strategy::DEFERRED }

    it do
      expect(service).to be_a(Applications::Defer)
    end
  end
end
