require Rails.root.join("db/seeds/base/constants")

module APITests
  module CallAPI
    def api_post(lead_provider:, path:, body:, with_server_date: nil)
      call_api(lead_provider:, path:, body:, method: :post, with_server_date:)
    end

    def api_put(lead_provider:, path:, body:, with_server_date: nil)
      call_api(lead_provider:, path:, body:, method: :put, with_server_date:)
    end

    def api_get(lead_provider:, path:, with_server_date: nil)
      call_api(lead_provider:, path:, body: nil, method: :get, with_server_date:)
    end

    def call_api(lead_provider:, path:, body:, method:, with_server_date: nil)
      api_token = token_for(lead_provider:)

      headers = {
        "Authorization" => "Bearer #{api_token}",
        "Content-Type" => "application/json",
      }
      headers["X-With-Server-Date"] = with_server_date if with_server_date.present?

      HTTParty.send(method, build_url(path:), body:, headers:)
    end

  private

    def build_url(path:)
      URI.join(ENV.fetch("HOSTING_DOMAIN", "http://localhost:3000"), path).to_s
    end

    def token_for(lead_provider:)
      token = LEAD_PROVIDER_CONFIG.dig(lead_provider.name, :token)
      raise "[CallApi] No seeded token found for '#{lead_provider.name}'" if token.nil?

      token
    end
  end
end
