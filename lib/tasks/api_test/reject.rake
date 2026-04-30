namespace :api_test do
  desc "Test the Reject endpoint"
  # Call the reject api endpoint using any pending application
  # or optionally with a specific application id
  # Usage when using any pending application:
  #    rake api_test:reject_application
  #
  # Usage when using a specific application
  #    rake api_test:reject_application\[279]
  #
  task :reject_application, %i[application_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    ::APITests::RejectApplication.new(application:).call
  end
end
