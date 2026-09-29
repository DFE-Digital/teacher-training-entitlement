module APITests
  class RevertToPendingApplication
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil)
      @application = application
    end

    def call
      if application.nil?
        raise "[RevertToPendingApplication] Could not find an accepted application"
      end

      path = revert_to_pending_api_v1_application_path(application.ecf_id)

      api_put(lead_provider: application.lead_provider, path:, body: nil)
    end

  private

    def application
      @application ||= Application
        .accepted_status
        .joins(:course)
        .where(courses: { identifier: Course::IDENTIFIERS })
        .last
    end
  end
end
