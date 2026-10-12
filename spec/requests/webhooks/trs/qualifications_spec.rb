require "swagger_helper"

# The `document` flag keeps these operations out of the lead provider docs
# when the spec runs under the default `rswag:specs:swaggerize` task; the
# `rswag:specs:swaggerize_webhooks` task sets RSWAG_WEBHOOKS to generate
# public/webhooks/docs/swagger.yaml instead.
RSpec.describe "webhooks/trs/qualifications", document: ENV["RSWAG_WEBHOOKS"].present?, type: :request do
  let(:token) { APIToken.create_with_random_token!(scope: :teacher_record_service) }
  let(:Authorization) { "Bearer #{token}" }

  path "/webhooks/trs/qualifications/{trn}" do
    get("show qualification") do
      tags :webhooks
      parameter name: :trn,
                in: :path,
                required: true,
                type: :string,
                description: "Teacher reference number"
      produces "application/json"
      security [{ api_key: [] }]

      response(200, "successful") do
        let(:user) { create(:user) }
        let(:trn) { user.trn }

        before { create(:outcome, user:) }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true),
            },
          }
        end

        run_test!
      end

      response(404, "not found - unknown TRN") do
        let(:trn) { "bad-trn" }

        run_test!
      end
    end
  end
end
