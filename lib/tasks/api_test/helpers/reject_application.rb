require_relative "call_api"

class RejectApplication
  include CallApi
  include Rails.application.routes.url_helpers

  def initialize(application: nil)
    @application = application
  end

  def call
    if application.nil?
      raise "[RejectApplication] Could not find a rejectable application"
    end

    body = {
      data: {
        type: "application",
        attributes: {
          reason: "other",
        },
      },
    }.to_json

    url = reject_api_v1_application_path(application.ecf_id)

    api_put(lead_provider: application.lead_provider, url:, body:)
  end

private

  def application
    @application ||= Application
      .pending_status
      .joins(:course)
      .where(courses: { identifier: Course::IDENTIFIERS })
      .last
  end
end
