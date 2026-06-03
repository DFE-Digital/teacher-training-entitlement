require "rails_helper"

RSpec.describe TeacherAuth::ActivateTrn do
  subject { described_class.new(access_token).call }

  let(:access_token) { "test-access-token" }

  describe "#call" do
    let(:expected_headers) do
      {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json",
        "X-Api-Version" => "20260416",
      }
    end

    context "when the request is successful with immediate TRN" do
      before do
        stub_request(:put, %r{/v3/trn-request/activate})
          .with(headers: expected_headers)
          .to_return(status: 200, body: { trn: "1234567" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns the TRN" do
        expect(subject).to eq(trn: "1234567")
      end
    end

    context "when the request is successful but TRN is pending" do
      before do
        stub_request(:put, %r{/v3/trn-request/activate})
          .with(headers: expected_headers)
          .to_return(status: 200, body: { trn: nil, status: "pending" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns nil TRN" do
        expect(subject).to eq(trn: nil)
      end
    end

    context "when the request fails" do
      before do
        stub_request(:put, %r{/v3/trn-request/activate})
          .with(headers: expected_headers)
          .to_return(status: 401, body: { error: "unauthorized" }.to_json)
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
