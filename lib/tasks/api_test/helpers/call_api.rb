module CallApi
  def call_api(lead_provider:, url:, body:)
    api_token = lead_provider.generate_token!

    headers = {
      "Authorization" => "Bearer #{api_token}",
      "Content-Type" => "application/json",
    }

    response = HTTParty.put(url, body:, headers:)

    APIToken.find_by_unhashed_token(api_token, scope: :lead_provider).delete

    response
  end
end
