namespace :data_migrations do
  desc "Copy application reason_for_rejection values into rejected state change metadata"
  task remove_reason_for_rejection_from_applications: :environment do
    unless Application.column_names.include?("reason_for_rejection")
      puts "Skipping: applications.reason_for_rejection does not exist"
      next
    end

    created_count = 0
    skipped_count = 0

    Application.where.not(reason_for_rejection: nil).find_each do |application|
      reason = Application.where(id: application.id).pick(:reason_for_rejection)

      existing_state_change = application
        .state_changes
        .where(event: Application::REJECTED)
        .where("metadata ->> 'reason' = ?", reason)
        .exists?

      if existing_state_change
        skipped_count += 1
        next
      end

      application.state_changes.create!(
        event: Application::REJECTED,
        lead_provider: application.lead_provider,
        metadata: { reason: },
      )

      created_count += 1
    end

    puts "Created #{created_count} rejected state changes"
    puts "Skipped #{skipped_count} applications with existing rejected state changes"
  end
end
