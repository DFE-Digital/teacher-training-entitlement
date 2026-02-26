require "rails_helper"

RSpec.describe Participants::Strategy, type: :model do
  subject(:service) { Participants::Strategy.for(application:, training_status:, reason:) }

  let(:application) { build(:application) }
  let(:training_status) { nil }
  let(:reason) { "other" }

  context "when withdrawing an application" do
    let(:training_status) { Participants::Strategy::WITHDRAWN }

    it do
      expect(service).to be_a(Participants::Withdraw)
    end
  end

  context "when resuming an application" do
    let(:training_status) { Participants::Strategy::ACTIVE }

    it do
      expect(service).to be_a(Participants::Resume)
    end
  end

  context "when deferring an application" do
    let(:training_status) { Participants::Strategy::DEFERRED }

    it do
      expect(service).to be_a(Participants::Defer)
    end
  end
end
