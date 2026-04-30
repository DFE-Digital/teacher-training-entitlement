module APITests
  class CompletedDeclaration
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil, has_passed: true, delivery_partner: nil)
      @application = application
      @has_passed = has_passed
      @delivery_partner = delivery_partner
    end

    def call
      if application.nil?
        raise "[StartedDeclaration] Could not find a started application"
      end

      body = {
        data:
        {
          attributes: {
            declaration_date: Time.current.utc.iso8601,
            delivery_partner_id:,
            has_passed: @has_passed.to_s.downcase.in?(%w[1 true yes]),
          },
        },
      }.to_json

      path = completed_declaration_api_v1_application_path(application.ecf_id)

      api_post(lead_provider: application.lead_provider, path:, body:)
    end

  private

    def delivery_partner_id
      @delivery_partner&.ecf_id || application.lead_provider.delivery_partners.first.ecf_id
    end

    def application
      @application ||= Application
        .started_status
        .joins(:course)
        .where(courses: { identifier: Course::IDENTIFIERS })
        .last
    end
  end
end
