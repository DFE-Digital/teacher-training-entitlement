namespace :data_migrations do
  desc "Backfill course-owned milestones and course cohort training starts from legacy course cohort milestones"
  task :backfill_course_milestones, %i[dry_run] => :environment do |_task, args|
    dry_run = args[:dry_run] != "false"
    updated_course_cohorts = 0
    updated_milestones = 0
    rewired_declarations = 0
    removed_legacy_milestones = 0
    skipped_milestones = 0
    course_milestone_keys = Milestone.unscoped.where.not(course_id: nil).pluck(:course_id, :declaration_type).to_set
    month_offset_between = lambda do |from_date, to_date|
      next if to_date.blank?

      (to_date.year * 12 + to_date.month) - (from_date.year * 12 + from_date.month)
    end

    CourseCohort.includes(:course).find_each do |course_cohort|
      legacy_milestones = Milestone.unscoped.where(course_cohort_id: course_cohort.id).to_a
      next if legacy_milestones.empty?

      training_starts_at = course_cohort.training_starts_at ||
        legacy_milestones.find { |milestone| milestone.declaration_type == Milestone::STARTED }&.acceptance_window_start_date ||
        legacy_milestones.filter_map(&:acceptance_window_start_date).min

      if training_starts_at.nil?
        puts "Skipping course cohort #{course_cohort.id}: no training start date could be inferred"
        skipped_milestones += legacy_milestones.size
        next
      end

      if course_cohort.training_starts_at.nil?
        puts "CourseCohort #{course_cohort.id}: training_starts_at -> #{training_starts_at}"
        course_cohort.update!(training_starts_at:) unless dry_run
        updated_course_cohorts += 1
      end

      legacy_milestones.each do |legacy_milestone|
        start_offset = month_offset_between.call(training_starts_at, legacy_milestone.acceptance_window_start_date)
        end_offset = month_offset_between.call(training_starts_at, legacy_milestone.acceptance_window_end_date)

        course_milestone_key = [course_cohort.course_id, legacy_milestone.declaration_type]
        course_milestone = Milestone.unscoped.find_by(course_id: course_cohort.course_id, declaration_type: legacy_milestone.declaration_type) if course_milestone_keys.include?(course_milestone_key)

        unless course_milestone_keys.include?(course_milestone_key)
          puts "Milestone #{legacy_milestone.id}: course_id -> #{course_cohort.course_id}, start_offset -> #{start_offset}, end_offset -> #{end_offset}"

          unless dry_run
            legacy_milestone.update!(
              course_id: course_cohort.course_id,
              acceptance_window_start_offset: start_offset,
              acceptance_window_end_offset: end_offset,
            )
          end

          updated_milestones += 1
          course_milestone_keys.add(course_milestone_key)
          next
        end

        if dry_run && course_milestone.nil?
          declarations_count = Declaration.where(milestone: legacy_milestone).count
          puts "Would rewire #{declarations_count} declarations from duplicate legacy milestone #{legacy_milestone.id} for course #{course_cohort.course_id} #{legacy_milestone.declaration_type}"
          rewired_declarations += declarations_count
          removed_legacy_milestones += 1 if declarations_count.zero?
          next
        end

        if course_milestone == legacy_milestone
          next
        end

        declarations = Declaration.where(milestone: legacy_milestone)
        if declarations.exists?
          declarations_count = declarations.count
          puts "Declaration milestone_id #{legacy_milestone.id} -> #{course_milestone.id} for #{declarations_count} declarations"
          declarations.update_all(milestone_id: course_milestone.id) unless dry_run
          rewired_declarations += declarations_count
        end

        next unless Declaration.where(milestone: legacy_milestone).none?

        puts "Removing duplicate legacy milestone #{legacy_milestone.id}"
        legacy_milestone.destroy! unless dry_run
        removed_legacy_milestones += 1
      end
    end

    puts "Dry run: #{dry_run}"
    puts "Updated course cohorts: #{updated_course_cohorts}"
    puts "Updated milestones: #{updated_milestones}"
    puts "Rewired declarations: #{rewired_declarations}"
    puts "Removed duplicate legacy milestones: #{removed_legacy_milestones}"
    puts "Skipped milestones: #{skipped_milestones}"
  end
end
