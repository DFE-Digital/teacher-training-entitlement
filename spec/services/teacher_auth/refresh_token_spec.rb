require "rails_helper"

RSpec.describe TeacherAuth::RefreshToken do
  subject { described_class.new(refresh_token).call }

  let(:refresh_token) { "old-refresh-token" }
  let(:new_access_token) { "new-access-token" }
  let(:new_refresh_token) { "new-refresh-token" }

  let(:success_response) do
    {
      "access_token" => new_access_token,
      "refresh_token" => new_refresh_token,
    }
  end

  describe "#call" do
    context "when the request is successful" do
      before do
        stub_request(:post, %r{/oauth2/token})
          .with(body: hash_including(grant_type: "refresh_token", refresh_token:))
          .to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns the new tokens" do
        expect(subject).to eq(access_token: new_access_token, refresh_token: new_refresh_token)
      end
    end

    context "when the request fails" do
      before do
        stub_request(:post, %r{/oauth2/token})
          .to_return(status: 400, body: { error: "invalid_grant" }.to_json)
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
