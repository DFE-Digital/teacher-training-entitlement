require "rails_helper"

RSpec.describe Applications::ChangeLeadProvider, type: :model do
  let(:old_provider) { create(:lead_provider) }
  let(:new_provider) { create(:lead_provider) }
  let(:application) { create(:application, :pending, lead_provider: old_provider) }

  subject(:service) { described_class.new(application:, new_provider:) }

  before { subject.call }

  it do
    expect(application.lead_provider).to eq(new_provider)
    expect(application.status).to eq(Application::PENDING)
    expect(application.application_lead_providers&.last&.lead_provider).to eq(old_provider)
    # TODO: check application_events
    # expect(application.application_events.last).to eq(something)
  end

  context "when application not pending" do
    let(:application) { create(:application, :accepted, lead_provider: old_provider) }

    it do
      expect(subject).to have_error(:application, :application_must_be_pending_status)
    end
  end

  context "when application provider is same as new provider" do
    let(:application) { create(:application, :pending, lead_provider: new_provider) }

    it do
      expect(subject).to have_error(:base, :provider_must_be_different)
    end
  end

  context "when application has previously been assigned to new provider" do
    let(:application) do
      create(:application, :pending,
             :with_application_lead_provider,
             old_lead_provider: new_provider,
             lead_provider: old_provider)
    end

    it do
      expect(subject).to have_error(:base, :previously_changed_to_provider)
    end
  end
end
