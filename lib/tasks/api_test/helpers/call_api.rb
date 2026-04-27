module CallApi
  def call_api(lead_provider:, url:, body: nil, method: :put)
    api_token = generate_token!(lead_provider:)

    headers = {
      "Authorization" => "Bearer #{api_token}",
      "Content-Type" => "application/json",
    }

<<<<<<< HEAD
    response = HTTParty.send(method, url, body:, headers:)
=======
    response = HTTParty.put(build_path(url:), body:, headers:)
>>>>>>> 1fdc929f (Add tools for API Testing)

    APIToken.find_by_unhashed_token(api_token, scope: :lead_provider).delete

    response
  end

private

  def build_path(url:)
    "#{ENV['BASE_API_URL'] || 'http://localhost:3000'}#{url}"
  end

  def generate_token!(lead_provider:)
    scope = APIToken.scopes[:lead_provider]
    APIToken.create_with_random_token!(scope:, lead_provider:)
  end
end
