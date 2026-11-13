require "rails_helper"

RSpec.describe Trs::WebhookSigningKeys do
  subject(:verification_key) { described_class.verification_key(key_id) }

  let(:key_id) { "trs-key-1" }
  let(:ec_key) { OpenSSL::PKey::EC.generate("secp384r1") }
  let(:jwks_url) { "#{Rails.application.config.x.trs_api_url}/webhook-jwks" }

  before do
    stub_request(:get, jwks_url).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: { keys: [JWT::JWK.new(ec_key, kid: "trs-key-1").export] }.to_json,
    )
  end

  it "returns a key that verifies signatures made with the published key" do
    signing_key = Linzer.new_ecdsa_p384_sha384_key(ec_key.to_pem, key_id)
    message = Linzer::Message.new(Net::HTTP::Post.new(URI("https://example.com/")).tap { it["ce-id"] = "123" })
    signature = Linzer.sign(signing_key, message, %w[ce-id])

    expect(Linzer.verify(verification_key, message, signature)).to be(true)
  end

  context "when the key ID is not published" do
    let(:key_id) { "unknown-key" }

    it { is_expected.to be_nil }
  end

  context "when TRS returns an error" do
    before { stub_request(:get, jwks_url).to_return(status: 503) }

    it "raises" do
      expect { verification_key }.to raise_error(described_class::FetchError)
    end
  end
end
