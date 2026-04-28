require_relative "helpers/change_delivery_partner"

namespace :api_test do
  desc "Test the Change Delivery Partner endpoint"
  # Call the change delivery partner api endpoint using any declaration
  # or optionally with a specific declaration id and delivery partner ids
  # Usage when using any declaration:
  #    rake api_test:change_delivery_partner
  #
  # Usage when using a specific declaration
  #    rake api_test:change_delivery_partner\[279]
  #
  # Usage when using a specific declaration and delivery partner ids
  #    rake api_test:change_delivery_partner\[279,123,456]
  #
  task :change_delivery_partner, %i[declaration_id delivery_partner_id secondary_delivery_partner_id] => :environment do |_t, args|
    declaration = if args[:declaration_id].present?
                    Declaration.find_by_id(args[:declaration_id])
                  end

    delivery_partner = if args[:delivery_partner_id].present?
                         DeliveryPartner.find_by_id(args[:delivery_partner_id])
                       end

    secondary_delivery_partner = if args[:secondary_delivery_partner_id].present?
                                   DeliveryPartner.find_by_id(args[:secondary_delivery_partner_id])
                                 end

    ChangeDeliveryPartner.new(
      declaration:,
      delivery_partner:,
      secondary_delivery_partner:,
    ).call
  end
end
