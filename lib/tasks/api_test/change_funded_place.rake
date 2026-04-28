require_relative "helpers/change_funded_place"

namespace :api_test do
  desc "Test the Change Funded Place endpoint"
  # Call the change funded place api endpoint using any accepted application
  # or optionally with a specific application id and / or funded_place flag
  # Usage when using any accepted application:
  #    rake api_test:change_funded_place
  #
  # Usage when using a specific application
  #    rake api_test:change_funded_place\[279]
  #
  # Usage when using a specific application and funded_place value
  #    rake api_test:change_funded_place\[279,true]
  #
  task :change_funded_place, %i[application_id funded_place] => :environment do |_t, args|
    application = if args[:application_id].present?
                    Application.find_by_id(args[:application_id])
                  end

    ChangeFundedPlace.new(application:, funded_place: args[:funded_place]).call
  end
end
