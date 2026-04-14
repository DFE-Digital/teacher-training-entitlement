require "rails_helper"

RSpec.describe Applications::ChangeLeadProvider, type: :model do
  let(:old_provider) { create(:lead_provider) }
  let(:new_provider) { create(:lead_provider) }
  let(:current_application) { create(:application, :pending, lead_provider: old_provider) }

  subject(:service) { described_class.new(current_application:, new_provider:) }

  before { subject.call }

  it do
    expect(Application.including_superceded.count).to eq(2)

    expect(current_application.lead_provider_id).to eq(new_provider.id)
    expect(current_application.status).to eq(Application::PENDING)

    new_application = Application
                      .including_superceded
                      .find_by_superceding_application_id(current_application.id)
    expect(new_application).not_to be_nil

    expect(new_application.ecf_id).to eq(current_application.ecf_id)

    expect(new_application.status).to eq(Application::SUPERCEDED)
    expect(new_application.lead_provider_id).to eq(old_provider.id)
  end
end
