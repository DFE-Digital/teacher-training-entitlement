require_relative "call_api"

class ListApplications
  include CallApi
  include Rails.application.routes.url_helpers

  def initialize(lead_provider: nil)
    @lead_provider = lead_provider || LeadProvider.last
  end

  def call
    if @lead_provider.nil?
      raise "[ListApplications] Could not find a lead provider"
    end

    url = api_v1_applications_url(host: "localhost:3000")

    response = call_api(lead_provider: @lead_provider, url:, method: :get)

    puts "status: #{response.code}" # rubocop:disable Rails/Output
    puts "response: #{response.parsed_response}" # rubocop:disable Rails/Output
  end
end
