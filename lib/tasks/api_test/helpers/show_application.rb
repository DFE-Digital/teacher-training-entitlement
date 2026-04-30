require_relative "call_api"

class ShowApplication
  include CallApi
  include Rails.application.routes.url_helpers

  def initialize(application: nil, lead_provider: nil)
    @application = application || Application.last
    @lead_provider = lead_provider || @application&.lead_provider
  end

  def call
    if @lead_provider.nil?
      raise "[ShowApplication] Could not find a lead provider"
    end

    if @application.nil?
      raise "[ShowApplication] Could not find an application"
    end

    url = api_v1_application_url(@application.ecf_id, host: "localhost:3000")

    response = call_api(lead_provider: @lead_provider, url:, method: :get)

    puts "status: #{response.code}" # rubocop:disable Rails/Output
    puts "response: #{response.parsed_response}" # rubocop:disable Rails/Output
  end
end
