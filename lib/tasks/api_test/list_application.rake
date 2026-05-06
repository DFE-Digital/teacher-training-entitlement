namespace :api_test do
  desc "Test the Applications#index endpoint"
  # Call the applications#index api endpoint with an optional lead_provider_id
  #
  # Usage when using any lead provider:
  #    rake api_test:list_applications
  #
  # Usage when using a specific lead provider
  #    rake api_test:list_applications\[8]
  #
  task :list_applications, %i[lead_provider_id] => :environment do |_t, args|
    lead_provider = if args[:lead_provider_id].present?
                      LeadProvider.find_by_id(args[:lead_provider_id])
                    end

    ::APITests::ListApplications.new(lead_provider:).call
  end
end
