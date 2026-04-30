require Rails.root.join("db/seeds/base/constants")

module APITests
  module CallAPI
    def api_post(lead_provider:, url:, body:)
      call_api(lead_provider:, url:, body:, method: :post)
    end

    def api_put(lead_provider:, url:, body:)
      call_api(lead_provider:, url:, body:, method: :put)
    end

    def api_get(lead_provider:, url:)
      call_api(lead_provider:, url:, body: nil, method: :get)
    end

    def call_api(lead_provider:, url:, body:, method:)
      api_token = token_for(lead_provider:)

      headers = {
        "Authorization" => "Bearer #{api_token}",
        "Content-Type" => "application/json",
      }

      HTTParty.send(method, build_path(url:), body:, headers:)
    end

  private

    def build_path(url:)
      "#{ENV['BASE_API_URL'] || 'http://localhost:3000'}#{url}"
    end

    def token_for(lead_provider:)
      token = LEAD_PROVIDER_TOKENS[lead_provider.name]
      raise "[CallApi] No seeded token found for '#{lead_provider.name}'" if token.nil?

      token
    end
  end
end
