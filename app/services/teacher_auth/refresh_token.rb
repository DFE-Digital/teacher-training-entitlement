module TeacherAuth
  class RefreshToken
    include HTTParty

    base_uri ENV.fetch("TEACHER_AUTH_DOMAIN", nil)

    def initialize(refresh_token)
      @refresh_token = refresh_token
    end

    def call
      response = self.class.post(
        "/oauth2/token",
        body: {
          grant_type: "refresh_token",
          refresh_token: @refresh_token,
          client_id: ENV.fetch("TEACHER_AUTH_CLIENT_ID", nil),
          client_secret: ENV.fetch("TEACHER_AUTH_CLIENT_SECRET", nil),
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
