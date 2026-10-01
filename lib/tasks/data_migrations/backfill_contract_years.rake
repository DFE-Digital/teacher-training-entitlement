namespace :data_migrations do
  desc "Backfill contract years for course_url and email"
  task :backfill_course_lead_provider_profiles, %i[dry_run] => :environment do |_task, args|
    dry_run = args[:dry_run] != "false"
    updated_profiles = 0
    created_profiles = 0

    course = Course.reception

    LeadProvider.find_each do |lead_provider|
      profile = ContractYear.find_by(lead_provider:, course:, academic_year: nil)
      if profile
        profile.update!(email: lead_provider.email, course_url: lead_provider.url) unless dry_run
        updated_profiles += 1
      else
        ContractYear.create!(lead_provider:, course:, academic_year: nil, email: lead_provider.email, course_url: lead_provider.url) unless dry_run
        created_profiles += 1
      end
    end

    puts "Dry run: #{dry_run}"
    puts "Updated profiles: #{updated_profiles}"
    puts "Created profiles: #{created_profiles}"
  end
end
