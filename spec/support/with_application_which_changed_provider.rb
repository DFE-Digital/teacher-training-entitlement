RSpec.shared_context "with application which changed provider" do
  let(:new_lead_provider) { create(:lead_provider) }
  let(:old_lead_provider) { create(:lead_provider) }
  let!(:new_application) { create(:application, lead_provider: new_lead_provider) }
  let!(:old_application) { create(:application, :superceded, lead_provider: old_lead_provider, superceding_application: new_application) } # rubocop:disable RSpec/LetSetup
end
