require_relative "constants"

LEAD_PROVIDERS.each do |name|
  LeadProvider.find_by(name:) || FactoryBot.create(:lead_provider, name:)
end
