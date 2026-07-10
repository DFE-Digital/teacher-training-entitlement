namespace :data_migrations do
  desc "Backfill application updated_at timestamps from provider change records"
  task backfill_application_updated_at_from_provider_changes: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true") != "false"

    changed_provider_applications = ApplicationLeadProvider
      .select("application_id, MAX(updated_at) AS latest_provider_updated_at")
      .group(:application_id)
      .having("COUNT(*) > 1")

    updated_count = 0
    skipped_count = 0

    Application
      .joins("INNER JOIN (#{changed_provider_applications.to_sql}) latest_provider_changes ON latest_provider_changes.application_id = applications.id")
      .select("applications.*, latest_provider_changes.latest_provider_updated_at")
      .find_each do |application|
        latest_provider_updated_at = application.latest_provider_updated_at

        if latest_provider_updated_at <= application.updated_at
          skipped_count += 1
          next
        end

        puts "Application #{application.id}: #{application.updated_at} -> #{latest_provider_updated_at}"

        application.update_columns(updated_at: latest_provider_updated_at) unless dry_run
        updated_count += 1
      end

    puts "Dry run: #{dry_run}"
    puts "#{dry_run ? 'Would update' : 'Updated'} #{updated_count} applications"
    puts "Skipped #{skipped_count} applications already newer than their provider changes"
  end
end
