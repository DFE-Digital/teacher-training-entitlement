require "linzer/rack"

module Trs
  class WebhookSignature
    class InvalidSignature < StandardError; end

    REQUIRED_COMPONENTS = %w[@target-uri content-digest content-length ce-id ce-type ce-time].freeze
    MAX_AGE = 5.minutes

    def initialize(request)
      @request = request
    end

    def call
      signature = Linzer::Signature.build(
        "signature-input" => header!("signature-input"),
        "signature" => header!("signature"),
      )

      missing_components = REQUIRED_COMPONENTS - signature.components
      raise InvalidSignature, "Signature does not cover #{missing_components.join(', ')}" if missing_components.any?

      key = WebhookSigningKeys.new(signature.parameters["keyid"]).call
      raise InvalidSignature, "Unknown signing key" unless key

      Linzer.verify(key, Linzer::Message.new(request.rack_request), signature, no_older_than: MAX_AGE.to_i)
      raise InvalidSignature, "content-digest does not match body" unless body_matches_digest?

      true
    rescue Linzer::Error => e
      raise InvalidSignature, e.message
    end

  private

    attr_reader :request

    def header!(name)
      request.headers[name].presence || raise(InvalidSignature, "Missing #{name} header")
    end

    def body_matches_digest?
      expected = header!("content-digest")[/sha-256=:([^:]+):/, 1]
      return false unless expected

      ActiveSupport::SecurityUtils.secure_compare(expected, Base64.strict_encode64(Digest::SHA256.digest(request.raw_post)))
    end
  end
end
