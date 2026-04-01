require "rails_helper"

RSpec.describe Applications::Strategy, type: :model do
  subject(:service) { Applications::Strategy.for(application:, status:, reason:, admin_user: create(:admin)) }

  let(:application) { build(:application) }
  let(:status) { nil }
  let(:reason) { "other" }

  context "when withdrawing an application" do
    let(:status) { Application::WITHDRAWN }

    it do
      expect(service).to be_a(Applications::Withdraw)
    end
  end

  context "when resuming an application" do
    let(:status) { Application::ACCEPTED }

    it do
      expect(service).to be_a(Applications::Resume)
    end
  end

  context "when deferring an application" do
    let(:status) { Application::DEFERRED }

    it do
      expect(service).to be_a(Applications::Defer)
    end
  end
end
