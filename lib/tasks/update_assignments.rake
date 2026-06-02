namespace :assignments do
  desc "update application lead_provider"
  task update: :environment do
    ApplicationLeadProvider.find_each do |alp|
      alp.assigned_at = alp.application&.created_at
      unless alp.current
        alp.unassigned_at = Time.zone.now
      end
      alp.save!
    end
  end
end
