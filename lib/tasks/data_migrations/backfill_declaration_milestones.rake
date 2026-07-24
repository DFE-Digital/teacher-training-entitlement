namespace :data_migrations do
  desc "Backfill milestones for declarations and link each declaration to its milestone"
  task :backfill_declaration_milestones, [:dry_run] => :environment do |_task, args|
    dry_run = ActiveModel::Type::Boolean.new.cast(args[:dry_run])
    created_milestone_count = 0
    updated_declaration_count = 0
    skipped_declaration_count = 0

    Declaration.where(milestone_id: nil).includes(application: :course_cohort).find_each do |declaration|
      course_cohort = declaration.application.course_cohort

      unless course_cohort&.schedule
        skipped_declaration_count += 1
        next
      end

      milestone = course_cohort.milestones.find_or_initialize_by(declaration_type: declaration.declaration_type)

      if milestone.new_record?
        milestone.assign_attributes(
          acceptance_window_start_date: course_cohort.schedule.acceptance_window_start,
          acceptance_window_end_date: course_cohort.schedule.acceptance_window_end,
        )

        puts "Creating milestone #{milestone.attributes.slice('course_cohort_id', 'declaration_type', 'acceptance_window_start_date', 'acceptance_window_end_date')}" unless Rails.env.test?

        milestone.save! unless dry_run
        created_milestone_count += 1
      end

      declaration.update_columns(milestone_id: milestone.id) unless dry_run
      updated_declaration_count += 1
    end

    unless Rails.env.test?
      puts "DRY RUN: no records were changed" if dry_run
      puts "Created #{created_milestone_count} milestones"
      puts "Updated #{updated_declaration_count} declarations"
      puts "Skipped #{skipped_declaration_count} declarations"
    end
  end
end
