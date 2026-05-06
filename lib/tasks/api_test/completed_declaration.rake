namespace :api_test do
  desc "Test the Completed Declaration endpoint"
  # Call the completed declaration api endpoint using any started application
  # or optionally with a specific application id, has_passed flag and / or delivery partner id
  # Usage when using any started application:
  #    rake api_test:completed_declaration
  #
  # Usage when using a specific application
  #    rake api_test:completed_declaration\[279]
  #
  # Usage when using a specific application, has_passed value and delivery partner id
  #    rake api_test:completed_declaration\[279,true,123]
  #
  task :completed_declaration, %i[application_id has_passed delivery_partner_id] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    delivery_partner = if args[:delivery_partner_id].present?
                         DeliveryPartner.find_by_id(args[:delivery_partner_id])
                       end

    ::APITests::CompletedDeclaration.new(
      application:,
      has_passed: args[:has_passed],
      delivery_partner:,
    ).call
  end
end
