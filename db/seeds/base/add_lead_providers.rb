require_relative "constants"

LEAD_PROVIDER_CONFIG.each do |name, config|
  lead_provider = LeadProvider.find_or_initialize_by(name:)
  lead_provider.assign_attributes(config.slice(:hint))
  lead_provider.save! if lead_provider.changed?
end
