module CallApi
  def call_api(lead_provider:, url:, body:)
    api_token = generate_token!(lead_provider:)

    headers = {
      "Authorization" => "Bearer #{api_token}",
      "Content-Type" => "application/json",
    }

    response = HTTParty.put(url, body:, headers:)

    APIToken.find_by_unhashed_token(api_token, scope: :lead_provider).delete

    response
  end

private

  def generate_token!(lead_provider:)
    scope = APIToken.scopes[:lead_provider]
    APIToken.create_with_random_token!(scope:, lead_provider:)
  end
end
