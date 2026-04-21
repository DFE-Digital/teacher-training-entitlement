module Middleware
  class SentryLeadProviderContext
    def initialize(app)
      @app = app
    end

    def call(env)
      tag_sentry_with_lead_provider(env) if Rack::Request.new(env).path =~ /^\/api\/v\d+\/.*$/
      @app.call(env)
    end

  private

    attr_reader :lead_provider

    def tag_sentry_with_lead_provider(env)
      lead_provider = env["current_lead_provider"]
      return if lead_provider.nil?

      Sentry.configure_scope do |scope|
        scope.set_tag("lead_provider_id",   lead_provider.id)
        scope.set_tag("lead_provider_name", lead_provider.name)
        scope.set_user(id: lead_provider.id, username: lead_provider.name)
        scope.set_context("lead_provider", { id: lead_provider.id, name: lead_provider.name })
      end
    end
  end
end
