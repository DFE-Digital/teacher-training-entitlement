module APITests
  class ResumeApplication
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil, cohort: nil)
      @application = application
      @cohort = cohort
    end

    def call
      if application.nil?
        raise "[ResumeApplication] Could not find a deferred application"
      end

      body = {
        data: {
          type: "application",
          attributes: {
            schedule_id: cohort.ecf_id,
          },
        },
      }.to_json

      path = resume_api_v1_application_path(application.ecf_id)

      api_put(lead_provider: application.lead_provider, path:, body:)
    end

  private

    def application
      @application ||= LeadProvider.find_each do |lead_provider|
        cohorts = training_live_cohorts_for(lead_provider:)
        next unless cohorts.any?

        applications = lead_provider.applications.deferred_status

        return applications.last if applications.any?
      end
    end

    def cohort
      @cohort ||= begin
        cohorts = training_live_cohorts_for(lead_provider: application.lead_provider)
        if cohorts.blank?
          raise "Cannot find any live cohorts for #{application.lead_provider.name}"
        end

        cohorts.last
      end
    end

    def training_live_cohorts_for(lead_provider:)
      lead_provider.cohorts.select(&:training_live?)
    end
  end
end
