module APITests
  class ResumeApplication
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(application: nil, course_cohort: nil)
      @application = application
      @course_cohort = course_cohort
    end

    def call
      if application.nil?
        raise "[ResumeApplication] Could not find a deferred application"
      end

      body = {
        data: {
          type: "application",
          attributes: {
            schedule_id: course_cohort.ecf_id,
          },
        },
      }.to_json

      path = resume_api_v1_application_path(application.ecf_id)

      api_put(lead_provider: application.lead_provider, path:, body:)
    end

  private

    def application
      @application ||= LeadProvider.find_each do |lead_provider|
        course_cohorts = training_live_course_cohorts_for(lead_provider:)
        next unless course_cohorts.any?

        applications = lead_provider.applications.deferred_status

        return applications.last if applications.any?
      end
    end

    def course_cohort
      @course_cohort ||= begin
        course_cohorts = training_live_course_cohorts_for(lead_provider: application.lead_provider)
        if course_cohorts.blank?
          raise "Cannot find any live course cohorts for #{application.lead_provider.name}"
        end

        course_cohorts.last
      end
    end

    def training_live_course_cohorts_for(lead_provider:)
      lead_provider.course_cohorts.select { |cc| cc.schedule&.training_live? }
    end
  end
end
