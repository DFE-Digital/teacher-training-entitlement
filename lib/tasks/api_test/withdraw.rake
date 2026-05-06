namespace :api_test do
  desc "Test the Withdraw endpoint"
  # Call the withdraw api endpoint using any accepted application
  # or optionally with a specific application id
  # Usage when using any accepted application:
  #    rake api_test:withdraw_application
  #
  # Usage when using a specific application
  #    rake api_test:withdraw_application\[279]
  #
  task :withdraw_application, %i[application_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    ::APITests::WithdrawApplication.new(application:).call
  end
end
