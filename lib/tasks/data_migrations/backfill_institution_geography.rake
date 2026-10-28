namespace :data_migrations do
  desc "Backfill institution country and subdivision codes"
  task :backfill_institution_geography, %i[] => :environment do |_task, _args|
    updated_count = 0

    Institution.includes(:institutionable).find_in_batches(batch_size: 1_000) do |institutions|
      Institution.transaction do
        institutions.each do |institution|
          attributes = Importers::CountryCodeAttributes.country_code_attributes_for(institution.institutionable)

          institution.update!(attributes)
          updated_count += 1
        end
      end
    end

    puts "Updated institutions: #{updated_count}" unless Rails.env.test?
  end
end
