require_relative "helpers/resume_application"

namespace :api_test do
  desc "Test the Resume endpoint"
  # Call the resume api endpoint using any deferred application
  # or optionally with a specific application id and / or course cohort id
  # Usage when using any deferred application/live course cohort:
  #    rake api_test:resume_application
  #
  # Usage when using a specific application and any live course cohort for that provider
  #    rake api_test:resume_application\[279]
  #
  # Usage when using a specific application and specific course cohort
  #    rake api_test:resume_application\[279 777]
  #
  task :resume_application, %i[application_id course_cohort_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    course_cohort = if args[:course_cohort_id].present?
                      CourseCohort.find_by_id(args[:course_cohort_id])
                    end

    ResumeApplication.new(application:, course_cohort:).call
  end
end
