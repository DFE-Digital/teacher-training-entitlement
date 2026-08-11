namespace :data_migrations do
  desc "Backfill course cohorts on delivery partnerships"
  task :backfill_delivery_partnership_course_cohorts, [:dry_run] => :environment do |_task, args|
    dry_run = ActiveModel::Type::Boolean.new.cast(args[:dry_run])
    updated_count = 0
    skipped_count = 0

    DeliveryPartnership.where(course_cohort_id: nil).find_each do |delivery_partnership|
      matching_course_cohorts = CourseCohort
        .joins(:course_cohort_providers)
        .where(
          cohort_id: delivery_partnership.cohort_id,
          course_cohort_providers: { lead_provider_id: delivery_partnership.lead_provider_id },
        )

      unless matching_course_cohorts.one?
        skipped_count += 1
        next
      end

      delivery_partnership.update_column(:course_cohort_id, matching_course_cohorts.pick(:id)) unless dry_run
      updated_count += 1
    end

    unless Rails.env.test?
      puts "DRY RUN: no records were changed" if dry_run
      puts "Updated #{updated_count} delivery partnerships"
      puts "Skipped #{skipped_count} delivery partnerships"
    end
  end
end
