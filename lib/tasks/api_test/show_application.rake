namespace :api_test do
  desc "Test the Applications#show endpoint"
  # Call the applications#shiow api endpoint
  # with an optional application_id and lead_provider_id
  #
  # Usage when using any lead provider/application:
  #    rake api_test:show_application
  #
  # Usage when using a specific application
  #    rake api_test:show_application\[123]
  #
  # Usage when using a specific application and lead provider
  #    rake api_test:show_application\[123,8]
  #
  task :show_application, %i[application_id lead_provider_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end
    lead_provider = if args[:lead_provider_id].present?
                      LeadProvider.find_by_id(args[:lead_provider_id])
                    end

    ::APITests::ShowApplication.new(application:, lead_provider:).call
  end
end
