namespace :api_test do
  desc "Test the Started Declaration endpoint"
  # Call the started declaration api endpoint using any accepted application
  # or optionally with a specific application id and / or delivery partner id
  # Usage when using any accepted application:
  #    rake api_test:started_declaration
  #
  # Usage when using a specific application
  #    rake api_test:started_declaration\[279]
  #
  # Usage when using a specific application and delivery partner id
  #    rake api_test:started_declaration\[279,123]
  #
  task :started_declaration, %i[application_id delivery_partner_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    delivery_partner = if args[:delivery_partner_id].present?
                         DeliveryPartner.find_by_id(args[:delivery_partner_id])
                       end

    ::APITests::StartedDeclaration.new(application:, delivery_partner:).call
  end
end
