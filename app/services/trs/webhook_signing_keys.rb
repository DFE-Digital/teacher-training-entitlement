module Trs
  class WebhookSigningKeys
    class FetchError < StandardError; end

    CACHE_KEY = "trs_webhook_jwks".freeze
    CACHE_DURATION = 1.hour

    def self.verification_key(key_id)
      new.verification_key(key_id)
    end

    def verification_key(key_id)
      jwk = JWT::JWK::Set.new(jwks).find { |key| key[:kid] == key_id }
      return unless jwk

      Linzer.new_ecdsa_p384_sha384_key(jwk.verify_key.to_pem, key_id)
    end

  private

    def jwks
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_DURATION) do
        response = HTTParty.get("#{Rails.application.config.x.trs_api_url}/webhook-jwks")
        raise FetchError, "Failed to fetch TRS webhook JWKS: #{response.code}" unless response.success?

        response.parsed_response
      end
    end
  end
end
