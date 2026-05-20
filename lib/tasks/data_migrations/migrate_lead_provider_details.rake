namespace :data_migrations do
  desc "Update provider url and h"
  task migrate_lead_provider_details: :environment do
    LeadProvider.where(url: nil).find_each do |lead_provider|
      url = urls[lead_provider.name]

      if url
        puts "Updating #{lead_provider.name} with #{url}"
        lead_provider.update!(url:, hint: hints[lead_provider.name])
      else
        puts "Cannot find url for #{lead_provider.name}"
      end
    end
  end
end
