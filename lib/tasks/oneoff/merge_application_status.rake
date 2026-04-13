namespace :oneoff do
  desc "Merge application status"
  task merge_application_status: :environment do
    Application.find_each do |application|
      #
      # Withdrawn application event - ensure the application status is also withdrawn
      #
      if application.application_events.where(event: "StateChange::Application::WITHDRAWN").any?
        application.update_columns(status: Application::WITHDRAWN)
      #
      # Deferred application event - ensure the application status is also deferred
      #
      elsif application.application_events.where(event: "StateChange::Application::DEFERRED").any?
        application.update_columns(status: Application::DEFERRED)
      #
      # Has a Completed declaration - ensure a corresponding application event
      #
      elsif application.declarations.where(declaration_type: Application::COMPLETED).any?
        application.update_columns(status: Application::COMPLETED)
        application.application_events.find_or_create_by!(event: "StateChange::Application::COMPLETED")
      #
      # Has a Started declaration - ensure a corresponding application event
      #
      elsif application.declarations.where(declaration_type: Application::STARTED).any?
        application.update_columns(status: Application::STARTED)
        application.application_events.find_or_create_by!(event: "StateChange::Application::STARTED")
      #
      # Reset to pending and wipe any application events and declarations
      #
      else
        application.update_columns(status: Application::PENDING)
        application.application_events.delete_all
        application.declarations.delete_all
      end
    end
  end
end
