module APITests
  class StartedDeclaration
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil, delivery_partner: nil)
      @application = application
      @delivery_partner = delivery_partner
    end

    def call
      if application.nil?
        raise "[StartedDeclaration] Could not find an accepted application"
      end

      body = {
        data:
        {
          attributes: {
            delivery_partner_id:,
            declaration_date:,
          },
        },
      }.to_json

      path = started_declaration_api_v1_application_path(application.ecf_id)

      api_post(lead_provider: application.lead_provider, path:, body:, with_server_date: declaration_date)
    end

  private

    def declaration_date
      application.cohort.training_starts_at.in_time_zone("UTC").iso8601
    end

    def delivery_partner_id
      @delivery_partner&.ecf_id || application.lead_provider.delivery_partners.first.ecf_id
    end

    def application
      @application ||= Application
        .accepted_status
        .joins(:course)
        .where(courses: { identifier: Course::IDENTIFIERS })
        .last
    end
  end
end
