module Helpers
  module TrsWebhookHelpers
    TRS_WEBHOOK_KEY_ID = "trs-key-1".freeze
    TRS_WEBHOOK_URL = "http://www.example.com/webhooks/trs/messages".freeze

    def trust_trs_webhook_signing_key
      stub_trs_webhook_jwks([JWT::JWK.new(trs_webhook_signing_key.material, kid: TRS_WEBHOOK_KEY_ID).export])
    end

    def stub_trs_webhook_jwks(keys)
      stub_request(:get, "#{Rails.application.config.x.trs_api_url}/webhook-jwks").to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { keys: }.to_json,
      )
    end

    def signed_trs_webhook_headers(body:, headers: {}, signed_at: Time.current, components: Trs::WebhookSignature::REQUIRED_COMPONENTS)
      unsigned = {
        "content-digest" => "sha-256=:#{Base64.strict_encode64(Digest::SHA256.digest(body))}:",
        "ce-id" => SecureRandom.uuid,
        "ce-type" => "trn_request.completed",
        "ce-time" => signed_at.iso8601,
      }.merge(headers)

      message = Linzer::Message.new(trs_webhook_request(body:, headers: unsigned).rack_request)
      unsigned.merge(Linzer.sign(trs_webhook_signing_key, message, components, created: signed_at.to_i).to_h)
    end

    def trs_webhook_request(body:, headers:)
      env = Rack::MockRequest.env_for(TRS_WEBHOOK_URL, method: "POST", input: body)
      headers.each { |name, value| env["HTTP_#{name.upcase.tr('-', '_')}"] = value }
      ActionDispatch::Request.new(env)
    end

  private

    def trs_webhook_signing_key
      @trs_webhook_signing_key ||= Linzer.generate_ecdsa_p384_sha384_key(TRS_WEBHOOK_KEY_ID)
    end
  end
end
