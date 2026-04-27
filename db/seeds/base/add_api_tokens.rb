require_relative "constants"

LEAD_PROVIDER_TOKENS.each do |name, token|
  lead_provider = LeadProvider.where(name:).first!
  APIToken.create_with_known_token!(token, lead_provider:)
end
