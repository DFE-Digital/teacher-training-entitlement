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
        nil
      end
    end
  end
end
