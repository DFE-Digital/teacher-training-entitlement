namespace :data_migrations do
  desc "Backfill course-level delivery partnerships from legacy course cohort partnerships"
  task :backfill_course_delivery_partnerships, %i[dry_run] => :environment do |_task, args|
    dry_run = args[:dry_run] != "false"
    backfilled_partnerships = 0
    removed_duplicates = 0
    differing_partner_sets = 0

    # Read through SQL: the task runs after the model has moved to course-level
    # partnerships but before the course_cohort_id column is dropped.
    legacy_rows = DeliveryPartnership.connection.select_all(<<~SQL.squish).to_a
      SELECT delivery_partnerships.id,
             delivery_partnerships.delivery_partner_id,
             delivery_partnerships.lead_provider_id,
             delivery_partnerships.course_cohort_id,
             course_cohorts.course_id
      FROM delivery_partnerships
      JOIN course_cohorts ON course_cohorts.id = delivery_partnerships.course_cohort_id
      WHERE delivery_partnerships.course_id IS NULL
    SQL

    # Report (lead provider, course) pairs whose partner sets differ between
    # cohorts before changing anything; after the backfill every partner
    # serves every cohort of the course.
    legacy_rows.group_by { |row| [row["lead_provider_id"], row["course_id"]] }.each do |(lead_provider_id, course_id), rows|
      partners_by_cohort = rows.group_by { |row| row["course_cohort_id"] }.transform_values { |cohort_rows| cohort_rows.map { |row| row["delivery_partner_id"] }.uniq.sort }
      next if partners_by_cohort.values.uniq.one?

      differing_partner_sets += 1
      details = partners_by_cohort.map { |course_cohort_id, partner_ids| "course cohort #{course_cohort_id}: [#{partner_ids.join(', ')}]" }.join(", ")
      puts "Lead provider #{lead_provider_id}, course #{course_id}: partner set differs between cohorts and will widen to all cohorts (#{details})"
    end

    groups = legacy_rows.group_by do |row|
      [row["delivery_partner_id"], row["lead_provider_id"], row["course_id"]]
    end

    groups.each do |(delivery_partner_id, lead_provider_id, course_id), rows|
      row = rows.min_by { |r| r["id"] }

      puts "DeliveryPartnership #{row['id']}: course_id -> #{course_id} " \
           "(delivery_partner_id: #{delivery_partner_id}, lead_provider_id: #{lead_provider_id})"

      # update_all: this data migration runs before course-level validations apply
      DeliveryPartnership.where(id: row["id"]).update_all(course_id:) unless dry_run
      backfilled_partnerships += 1

      duplicates = rows - [row]
      duplicates.each do |duplicate|
        puts "Removing duplicate DeliveryPartnership #{duplicate['id']} " \
             "(delivery_partner_id: #{delivery_partner_id}, lead_provider_id: #{lead_provider_id}, course_id: #{course_id})"

        DeliveryPartnership.where(id: duplicate["id"]).delete_all unless dry_run
      end
      removed_duplicates += duplicates.size
    end

    puts "Dry run: #{dry_run}"
    puts "Backfilled partnerships: #{backfilled_partnerships}"
    puts "Removed duplicate partnerships: #{removed_duplicates}"
    puts "Lead provider/course pairs with partner sets differing between cohorts: #{differing_partner_sets}"
  end
end
