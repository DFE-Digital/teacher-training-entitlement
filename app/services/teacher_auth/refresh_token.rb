module TeacherAuth
  class RefreshToken
    include HTTParty

    base_uri Rails.application.config.x.teacher_auth.domain

    def initialize(refresh_token)
      @refresh_token = refresh_token
    end

    def call
      response = self.class.post(
        "/oauth2/token",
        body: {
          grant_type: "refresh_token",
          refresh_token: @refresh_token,
          client_id: Rails.application.config.x.teacher_auth.client_id,
          client_secret: Rails.application.config.x.teacher_auth.client_secret,
        },
      )

      if response.success?
        {
          access_token: response.parsed_response["access_token"],
          refresh_token: response.parsed_response["refresh_token"],
        }
      else
        Rails.logger.error("TeacherAuth::RefreshToken failed: #{response.code} - #{response.body}")
        invalid_grant?(response) ? :invalid_token : nil
      end
    end

  private

    def invalid_grant?(response)
      return false unless response.code == 400

      response.parsed_response["error"] == "invalid_grant"
    end
  end
end
