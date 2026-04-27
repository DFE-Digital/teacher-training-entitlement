module CallApi
  def api_post(lead_provider:, url:, body:)
    call_api(lead_provider:, url:, body:, method: :post)
  end

  def api_put(lead_provider:, url:, body:)
    call_api(lead_provider:, url:, body:, method: :put)
  end

  def call_api(lead_provider:, url:, body:, method:)
    api_token = generate_token!(lead_provider:)

    headers = {
      "Authorization" => "Bearer #{api_token}",
      "Content-Type" => "application/json",
    }
    response = HTTParty.send(method, build_path(url:), body:, headers:)

    APIToken.find_by_unhashed_token(api_token, scope: :lead_provider).delete

    puts "status: #{response.code}" # rubocop:disable Rails/Output
    puts "response: #{response.parsed_response}" # rubocop:disable Rails/Output

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
