namespace :data_migrations do
  desc "Backfill applications.registration_data from applications.raw_application_data"
  task backfill_application_registration_data: :environment do
    unless Application.column_names.include?("registration_data")
      puts "Skipping: applications.registration_data does not exist" unless Rails.env.test?
      next
    end

    unless Application.column_names.include?("raw_application_data")
      puts "Skipping: applications.raw_application_data does not exist"
      next
    end

    updated_count = 0
    skipped_count = 0

    Application.find_each do |application|
      if application.registration_data.present? || application.raw_application_data.blank?
        skipped_count += 1
        next
      end

      application.update_column(:registration_data, application.raw_application_data || {})
      updated_count += 1
    end

    puts "Updated #{updated_count} applications" unless Rails.env.test?
    puts "Skipped #{skipped_count} applications with existing registration data" unless Rails.env.test?
  end
end
