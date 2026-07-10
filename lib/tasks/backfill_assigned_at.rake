namespace :assignments do
  desc "update application lead_provider assigned_at"
  task update_assigned_at: :environment do
    ApplicationLeadProvider.find_each do |alp|
      alp.assigned_at ||= alp.created_at
      alp.save!
    end
  end
end
