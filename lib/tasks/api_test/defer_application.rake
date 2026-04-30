namespace :api_test do
  desc "Test the Defer endpoint"
  # Call the defer api endpoint using any deferred application
  # or optionally with a specific application id
  # Usage when using any started application:
  #    rake api_test:defer_application
  #
  # Usage when using a specific application
  #    rake api_test:defer_application\[279]
  #
  task :defer_application, %i[application_id course_cohort_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    ::APITests::DeferApplication.new(application:).call
  end
end
