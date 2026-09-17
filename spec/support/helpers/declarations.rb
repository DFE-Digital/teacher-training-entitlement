module Helpers
  module Declarations
    def started_received(application:, statement:, milestone:)
      application.update!(status: Application::STARTED)
      lead_provider = statement.lead_provider.reload
      create(
        :declaration, :eligible, :started,
        application:,
        statement:,
        milestone:,
        lead_provider:,
        delivery_partner: delivery_partner_for(application:, lead_provider:),
        value: 0.6
      )
    end

    def completed_received(application:, statement:, milestone:)
      application.update!(status: Application::COMPLETED)
      lead_provider = statement.lead_provider.reload
      create(
        :declaration, :eligible, :completed,
        application:,
        statement:,
        milestone:,
        lead_provider:,
        delivery_partner: delivery_partner_for(application:, lead_provider:),
        value: 0.4
      )
    end

    def clawback_received(application, milestone:)
      declaration = application.declarations.find_by(milestone:)
      declaration.clawback!
    end

    def delivery_partner_for(application:, lead_provider:)
      lead_provider.reload.delivery_partners_for_course_cohort(course_cohort: application.course_cohort).first ||
        create(
          :delivery_partner,
          name: "Delivery Partner #{SecureRandom.uuid}",
          lead_providers: { application.course_cohort => lead_provider },
        )
    end
  end
end
