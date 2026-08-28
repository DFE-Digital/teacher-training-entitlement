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
            declaration_date:,
            delivery_partner_id:,
            has_passed: @has_passed.to_s.downcase.in?(%w[1 true yes]),
          },
        },
      }.to_json

      path = completed_declaration_api_v1_application_path(application.ecf_id)

      api_post(lead_provider: application.lead_provider, path:, body:, with_server_date: declaration_date)
    end

  private

    def declaration_date
      milestone = application.milestones.find_by(declaration_type: :completed)
      milestone.acceptance_window_start_date.in_time_zone("UTC").iso8601
    end

    def delivery_partner_id
      @delivery_partner&.ecf_id || application.course_cohort.delivery_partners.first.ecf_id
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
