require_relative "call_api"

class DeferApplication
  include CallApi
  include Rails.application.routes.url_helpers

  def initialize(application: nil)
    @application = application
  end

  def call
    if application.nil?
      raise "[DeferApplication] Could not find a deferred application"
    end

    body = {
      data: {
        type: "application",
        attributes: {
          reason: "other",
        },
      },
    }.to_json

    url = defer_api_v1_application_url(application.ecf_id, host: "localhost:3000")

    response = call_api(lead_provider: application.lead_provider, url:, body:)

    puts "status: #{response.code}" # rubocop:disable Rails/Output
    puts "response: #{response.parsed_response}" # rubocop:disable Rails/Output
  end

private

  def application
    @application ||= Application
      .started_status
      .joins(:course)
      .where(courses: { identifier: Course::IDENTIFIERS })
      .last
  end
end
