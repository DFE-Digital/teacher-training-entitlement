module APITests
  class ChangeFundedPlace
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil, funded_place: false)
      @application = application
      @funded_place = funded_place
    end

    def call
      if application.nil?
        raise "[ChangeFundedPlace] Could not find an accepted application"
      end

      body = {
        data:
        {
          attributes: {
            funded_place: @funded_place.to_s.downcase.in?(%w[1 true yes]),
          },
        },
      }.to_json

      url = change_funded_place_api_v1_application_path(application.ecf_id)

      api_put(lead_provider: application.lead_provider, url:, body:)
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
