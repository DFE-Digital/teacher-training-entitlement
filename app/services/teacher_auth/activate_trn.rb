module TeacherAuth
  class ActivateTrn
    include HTTParty

    REQUIRED_API_VERSION = "20260416".freeze

    base_uri ENV.fetch("TRS_API_URL", nil)

    def initialize(access_token)
      @access_token = access_token
    end

    def call
      response = self.class.put(
        "/v3/trn-request/activate",
        headers: {
          "Authorization" => "Bearer #{@access_token}",
          "Content-Type" => "application/json",
          "X-Api-Version" => REQUIRED_API_VERSION,
        },
      )

      unless response.success?
        Rails.logger.error("TeacherAuth::ActivateTrn failed: #{response.code} - #{response.body}")
        Sentry::Metrics.count(
          "teacher_auth.activate_trn.failure",
          value: 1,
          attributes: { status_code: response.code },
        )
        return
      end

      return unless response.parsed_response

      { trn: response.parsed_response["trn"] }
    end
  end
end
