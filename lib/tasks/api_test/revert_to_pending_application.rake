namespace :api_test do
  desc "Test the Revert to Pending endpoint"
  # Call the revert to pending api endpoint using any accepted application
  # or optionally with a specific application id
  # Usage when using any accepted application:
  #    rake api_test:revert_to_pending_application
  #
  # Usage when using a specific application
  #    rake api_test:revert_to_pending_application\[279]
  #
  task :revert_to_pending_application, %i[application_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    ::APITests::RevertToPendingApplication.new(application:).call
  end
end
