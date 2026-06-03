unless Rails.env.test?
  Rails.application.config.x.teacher_auth.domain = ENV.fetch("TEACHER_AUTH_DOMAIN")
  Rails.application.config.x.teacher_auth.client_id = ENV.fetch("TEACHER_AUTH_CLIENT_ID")
  Rails.application.config.x.teacher_auth.client_secret = ENV.fetch("TEACHER_AUTH_CLIENT_SECRET")
  Rails.application.config.x.teacher_auth.one_login_home_url = ENV.fetch("ONE_LOGIN_HOME_URL")
  Rails.application.config.x.trs_api_url = ENV.fetch("TRS_API_URL")
end
