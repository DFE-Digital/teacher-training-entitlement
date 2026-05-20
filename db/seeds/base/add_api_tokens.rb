require_relative "constants"

LEAD_PROVIDER_CONFIG.each do |name, config|
  token = config[:token]
  next if token.blank?

  lead_provider = LeadProvider.where(name:).first!
  APIToken.create_with_known_token!(token, lead_provider:)
end
