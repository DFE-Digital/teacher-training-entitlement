module APITests
  class WithdrawApplication
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil)
      @application = application
    end

    def call
      if application.nil?
        raise "[WithdrawApplication] Could not find a withdrawable application"
      end

      body = {
        data: {
          type: "application",
          attributes: {
            reason: "other",
          },
        },
      }.to_json

      path = withdraw_api_v1_application_path(application.ecf_id)

      api_put(lead_provider: application.lead_provider, path:, body:)
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
