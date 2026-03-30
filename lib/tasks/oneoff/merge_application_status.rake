namespace :oneoff do
  desc "Merge application status"
  task merge_application_status: :environment do
    Application.find_each do |application|
      #
      # Withdrawn application state - ensure the application status is also withdrawn
      #
      if application.application_states.where(status: Application::WITHDRAWN).any?
        application.update_columns(status: Application::WITHDRAWN)
      #
      # Deferred application state - ensure the application status is also deferred
      #
      elsif application.application_states.where(status: Application::DEFERRED).any?
        application.update_columns(status: Application::DEFERRED)
      #
      # Has a Completed declaration- ensure a corresponding application state
      #
      elsif application.declarations.where(declaration_type: Application::COMPLETED).any?
        application.update_columns(status: Application::COMPLETED)
        application.application_states.find_or_create_by!(status: Application::COMPLETED)
      #
      # Has a Started declaration- ensure a corresponding application state
      #
      elsif application.declarations.where(declaration_type: Application::STARTED).any?
        application.update_columns(status: Application::STARTED)
        application.application_states.find_or_create_by!(status: Application::STARTED)
      end
    end
  end
end
