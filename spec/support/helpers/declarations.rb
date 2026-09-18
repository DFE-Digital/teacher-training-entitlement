module Helpers
  module Declarations
    def started_received(application:, statement:, milestone:)
      application.update!(status: Application::STARTED)
      create(
        :declaration, :eligible, :started,
        application:,
        statement:,
        milestone:,
        lead_provider: statement.lead_provider,
        value: 0.6
      )
    end

    def completed_received(application:, statement:, milestone:)
      application.update!(status: Application::COMPLETED)
      create(
        :declaration, :eligible, :completed,
        application:,
        statement:,
        milestone:,
        lead_provider: statement.lead_provider,
        value: 0.4
      )
    end

    def clawback_received(application, milestone:)
      declaration = application.declarations.find_by(milestone:)
      declaration.clawback!
    end
  end
end
