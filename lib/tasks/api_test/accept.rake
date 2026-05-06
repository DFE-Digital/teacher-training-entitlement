namespace :api_test do
  desc "Test the Accept endpoint"
  # Call the accept api endpoint using any pending application
  # or optionally with a specific application id and / or funded_place flag
  # Usage when using any pending application:
  #    rake api_test:accept_application
  #
  # Usage when using a specific application
  #    rake api_test:accept_application\[279]
  #
  # Usage when using a specific application and funded_place value
  #    rake api_test:accept_application\[279,true]
  #
  task :accept_application, %i[application_id funded_place] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    ::APITests::AcceptApplication.new(application:, funded_place: args[:funded_place]).call
  end
end
