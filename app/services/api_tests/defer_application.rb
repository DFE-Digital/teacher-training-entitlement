module APITests
  class DeferApplication
    include CallAPI
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

      path = defer_api_v1_application_path(application.ecf_id)

      api_put(lead_provider: application.lead_provider, path:, body:)
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
end
