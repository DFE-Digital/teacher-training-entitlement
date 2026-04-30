RSpec.shared_context "with application which changed provider" do
  let(:new_lead_provider) { create(:lead_provider) }
  let(:current_lead_provider) { new_lead_provider }
  let(:old_lead_provider) { create(:lead_provider) }
  let!(:application) { create(:application, :with_application_lead_provider, lead_provider: new_lead_provider, old_lead_provider:) } # rubocop:disable RSpec/LetSetup
end
