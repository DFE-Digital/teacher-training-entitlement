module APITests
  class AcceptApplication
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil, funded_place: false)
      @application = application
      @funded_place = funded_place
    end

    def call
      if application.nil?
        raise "[AcceptApplication] Could not find a pending application"
      end

      body = {
        data:
        {
          attributes: {
            funded_place: @funded_place.to_s.downcase.in?(%w[1 true yes]),
          },
        },
      }.to_json

      path = accept_api_v1_application_path(application.ecf_id)

      api_put(lead_provider: application.lead_provider, path:, body:)
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
end
