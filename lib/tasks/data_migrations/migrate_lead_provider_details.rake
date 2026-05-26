OLD_NAMES_MAP = {
  "UCL Institute of Education" => "University College London (UCL) Institute of Education",
}.freeze

DELETED_LPS = ["Teach First"].freeze

namespace :data_migrations do
  desc "Update provider url and h"
  task migrate_lead_provider_details: :environment do
    LeadProvider.where(url: nil).find_each do |lead_provider|
      config = LEAD_PROVIDER_CONFIG[lead_provider.name]

      # If the name has changed, update it
      if config.nil? && OLD_NAMES_MAP[lead_provider.name].present?
        lead_provider.update!(name: OLD_NAMES_MAP[lead_provider.name])

        config = LEAD_PROVIDER_CONFIG[lead_provider.name]
      end

      if config.nil?
        puts "Cannot find config for #{lead_provider.name}"
        next
      end

      puts "Updating #{lead_provider.name} with #{config[:url]}"
      lead_provider.update!(url: config[:url], hint: config[:hint])
    end
  end
end
