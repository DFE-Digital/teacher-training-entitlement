RSpec.shared_context "with application which changed provider" do
  let(:new_lead_provider) { create(:lead_provider) }
  let(:old_lead_provider) { create(:lead_provider) }
  let(:another_old_lead_provider) { create(:lead_provider) }
  let(:current_lead_provider) { new_lead_provider }
  let(:application) { create(:application) }

  # Set up the data so there are multiple providers with current_lead_provider
  # having been the first chosen, then reassigned to several others and then
  # back to the current provider.
  #
  # Assignment history, most recently assigned last:
  #
  # | lead_provider                   | current? |
  # |---------------------------------|----------|
  # | current_lead_provider           | false    |
  # | old_lead_provider          | false    |
  # | another_old_lead_provider  | false    |
  # | old_lead_provider          | false    |
  # | current_lead_provider           | true     |
  #
  before do
    create(:application_lead_provider, :unassigned, application:, lead_provider: current_lead_provider)
    create(:application_lead_provider, :unassigned, application:, lead_provider: old_lead_provider)
    create(:application_lead_provider, :unassigned, application:, lead_provider: another_old_lead_provider)
    create(:application_lead_provider, :unassigned, application:, lead_provider: old_lead_provider)
    create(:application_lead_provider, :current, application:, lead_provider: current_lead_provider)
  end
end
