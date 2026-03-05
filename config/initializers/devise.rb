# frozen_string_literal: true

require "omniauth/strategies/teacher_auth"

Devise.setup do |config|
  require "devise/orm/active_record"

  if Rails.env.test?
    config.secret_key = "devisebequiet1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  end

  if Rails.configuration.x.teacher_auth.enabled
    oidc_domain = ENV["TEACHER_AUTH_DOMAIN"].presence

    config.omniauth :teacher_auth,
                    callback_path: "/users/auth/teacher_auth/callback",
                    client_options: {
                      host: oidc_domain ? URI(oidc_domain).host : nil,
                      identifier: ENV.fetch("TEACHER_AUTH_CLIENT_ID", nil),
                      redirect_uri:
                        "#{ENV.fetch("HOSTING_DOMAIN", nil)}/users/auth/teacher_auth/callback",
                      secret: ENV.fetch("TEACHER_AUTH_CLIENT_SECRET", nil),
                    },
                    issuer: oidc_domain,
                    post_logout_redirect_uri:
                      "#{ENV.fetch("HOSTING_DOMAIN", nil)}/sign-out",
                    strategy_class: Omniauth::Strategies::TeacherAuth
  end
end
