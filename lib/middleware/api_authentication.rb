module Middleware
  class ApiAuthentication
    include ActionController::HttpAuthentication::Token

    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      if Rack::Request.new(env).path.match?(%r{^/+api/v\d+(/.*)?$})
        authenticate_lead_provider(env, request)
        return unauthenticated if env["current_lead_provider"].nil?
      end
      @app.call(env)
    end

  private

    def authenticate_lead_provider(env, request)
      token, _options = token_and_options(request)
      return if token.blank?

      env["current_lead_provider"] = resolve_lead_provider(token)
    end

    def resolve_lead_provider(token)
      cache_key = "lead_provider:#{Digest::SHA256.hexdigest(token)}"

      Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        api_token = APIToken.find_by_unhashed_token(token, scope: APIToken.scopes[:lead_provider])
        if api_token
          api_token.update!(last_used_at: Time.zone.now)
          api_token.lead_provider
        else
          raise ActiveRecord::RecordNotFound, "token not found"
        end
      end
    rescue StandardError => e
      Sentry.capture_exception(e)
      nil
    end

    def unauthenticated
      Rack::Response.new(
        JSON.generate({ error: I18n.t(:unauthorized) }),
        401,
        { "Content-Type" => "application/json" },
      ).to_a
    end
  end
end
