namespace :data_migrations do
  desc "Copy application accepted_at values into accepted state change metadata"
  task migrate_accepted_at_from_applications: :environment do
    unless Application.column_names.include?("accepted_at")
      puts "Skipping: applications.accepted_at does not exist"
      next
    end

    created_count = 0
    skipped_count = 0

    Application.where.not(accepted_at: nil).find_each do |application|
      accepted_at = Application.where(id: application.id).pick(:accepted_at)

      existing_state_change = application
        .state_changes
        .where(event: Application::ACCEPTED)
        .exists?

      if existing_state_change
        skipped_count += 1
        next
      end

      application.state_changes.create!(
        event: Application::ACCEPTED,
        lead_provider: application.lead_provider,
        created_at: accepted_at,
        updated_at: accepted_at,
      )

      created_count += 1
    end

    puts "Created #{created_count} rejected state changes"
    puts "Skipped #{skipped_count} applications with existing accepted state changes"
  end
end
