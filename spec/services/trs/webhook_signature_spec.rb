require "rails_helper"

RSpec.describe Trs::WebhookSignature do
  subject(:verify) { described_class.verify!(trs_webhook_request(body: delivered_body, headers: delivered_headers)) }

  let(:body) { { trnRequest: { oneLoginUserSubject: "one-login-id", trn: "1234567" } }.to_json }
  let(:delivered_body) { body }
  let(:headers) { signed_trs_webhook_headers(body:) }
  let(:delivered_headers) { headers }

  before { trust_trs_webhook_signing_key }

  it "accepts a message signed by TRS" do
    expect(verify).to be(true)
  end

  context "when the body has been swapped after signing" do
    let(:delivered_body) { { trnRequest: { oneLoginUserSubject: "someone-else", trn: "7654321" } }.to_json }

    it { expect { verify }.to raise_error(described_class::InvalidSignature, "content-digest does not match body") }
  end

  context "when a signed header has been changed" do
    let(:delivered_headers) { headers.merge("ce-type" => "ping") }

    it { expect { verify }.to raise_error(described_class::InvalidSignature) }
  end

  context "when the signature does not cover the content digest" do
    let(:headers) { signed_trs_webhook_headers(body:, components: described_class::REQUIRED_COMPONENTS - %w[content-digest]) }

    it { expect { verify }.to raise_error(described_class::InvalidSignature, "Signature does not cover content-digest") }
  end

  context "when the signature is too old" do
    let(:headers) { signed_trs_webhook_headers(body:, signed_at: 10.minutes.ago) }

    it { expect { verify }.to raise_error(described_class::InvalidSignature) }
  end

  context "when the signing key is unknown" do
    before { allow(Trs::WebhookSigningKeys).to receive(:verification_key).and_return(nil) }

    it { expect { verify }.to raise_error(described_class::InvalidSignature, "Unknown signing key") }
  end

  context "when the signature headers are missing" do
    let(:delivered_headers) { headers.except("signature", "signature-input") }

    it { expect { verify }.to raise_error(described_class::InvalidSignature, "Missing signature-input header") }
  end
end
