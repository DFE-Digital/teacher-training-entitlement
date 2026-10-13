require "rails_helper"

RSpec.describe "Webhooks::TRS", type: :request do
  describe "GET /webhooks/trs/qualifications/:trn" do
    let(:user) { create(:user) }
    let(:token) { APIToken.create_with_random_token!(scope: :webhook) }
    let!(:outcome) { create(:outcome, user:) }
    let(:trn) { user.trn }

    context "when request token is missing" do
      before { get webhooks_trs_qualification_path(trn) }

      it { expect(response).to have_http_status(:unauthorized) }

      it "responds with a WWW-Authenticate challenge" do
        expect(response.headers["WWW-Authenticate"]).to match(/\AToken /)
      end

      it "returns no qualification data" do
        expect(response.body).not_to include("qualifications")
      end
    end

    context "with a request token" do
      before { api_get(webhooks_trs_qualification_path(trn), token:) }

      context "when request token is invalid" do
        let(:token) { "bad-token" }

        it { expect(response).to have_http_status(:forbidden) }
      end

      context "when trn does not exists in service" do
        let(:trn) { "bad-trn" }

        it do
          expect(response).to have_http_status(:not_found)
          expect(response.content_type).to match(/application\/json.*/)
        end
      end

      context "when user has not outcome" do
        let(:other_user) { create(:user) }
        let(:trn) { other_user.trn }
        let(:expected_data) do
          {
            "data" => {
              "trn" => other_user.trn,
              "qualifications" => [],
            },
          }
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(/application\/json.*/)
          expect(parsed_response).to eq(expected_data)
        end
      end

      context "when user has some outcomes" do
        let(:expected_data) do
          {
            "data" => {
              "trn" => user.trn,
              "qualifications" => [
                {
                  "award_date" => outcome.completion_date.to_fs(:succint),
                  "course_type" => outcome.course_short_code,
                },
              ],
            },
          }.stringify_keys
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(/application\/json.*/)
          expect(parsed_response).to eq(expected_data)
        end
      end
    end
  end
end
