namespace :data_migrations do
  desc "Backfill lead_provider_id on application events from the application's current lead provider"
  task backfill_application_event_lead_providers: :environment do
    updated_count = 0
    skipped_count = 0

    ApplicationEvent
      .where(lead_provider_id: nil)
      .includes(application: :current_application_lead_provider)
      .find_each do |application_event|
        lead_provider = application_event.application.current_application_lead_provider&.lead_provider

        if lead_provider.nil?
          skipped_count += 1
          next
        end

        application_event.update!(lead_provider:)
        updated_count += 1
      end

    puts "Updated #{updated_count} application events"
    puts "Skipped #{skipped_count} application events without a current lead provider"
  end
end
