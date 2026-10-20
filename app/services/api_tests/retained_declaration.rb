module APITests
  class RetainedDeclaration
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(declaration_type:, application: nil, delivery_partner: nil)
      @application = application
      @declaration_type = declaration_type
      @delivery_partner = delivery_partner
    end

    def call
      raise "[RetainedDeclaration] Could not find a started application" if application.nil?

      body = {
        data: {
          attributes: {
            declaration_date:,
            delivery_partner_id:,
          },
        },
      }.to_json

      path = declaration_api_v1_application_path(application.ecf_id, declaration_type:)

      api_post(lead_provider: application.lead_provider, path:, body:, with_server_date: declaration_date)
    end

  private

    attr_reader :declaration_type

    def declaration_date
      milestone = application.milestones.find_by(declaration_type:)
      # Not all courses support retained milestones but we might still want to test
      # what happens so if we cannot find one then use the started.
      if milestone.nil?
        milestone = application.milestones.started.first
      end
      milestone.acceptance_window_start_date_for(training_starts_at: application.training_starts_at).in_time_zone("UTC").iso8601
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
