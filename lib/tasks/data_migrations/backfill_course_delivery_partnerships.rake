namespace :data_migrations do
  desc "Backfill delivery_partnerships.course_id from course_cohorts and remove duplicates"
  task :backfill_course_delivery_partnerships, %i[dry_run] => :environment do |_task, args|
    dry_run = args[:dry_run] != "false"
    connection = DeliveryPartnership.connection

    # Raw SQL: the task runs after the model has moved to course-level
    # partnerships but before the course_cohort_id column is dropped.
    DeliveryPartnership.transaction do
      # Remove duplicates first, keeping the lowest id per
      # (delivery partner, lead provider, course), so the backfill does not
      # violate the course-level unique index.
      removed = connection.exec_delete(<<~SQL.squish)
        WITH ranked AS (
          SELECT dp.id,
                 ROW_NUMBER() OVER (
                   PARTITION BY dp.delivery_partner_id, dp.lead_provider_id, COALESCE(dp.course_id, cc.course_id)
                   ORDER BY dp.id
                 ) AS position
          FROM delivery_partnerships dp
          LEFT JOIN course_cohorts cc ON cc.id = dp.course_cohort_id
          WHERE COALESCE(dp.course_id, cc.course_id) IS NOT NULL
        )
        DELETE FROM delivery_partnerships
        WHERE id IN (SELECT id FROM ranked WHERE position > 1)
      SQL

      backfilled = connection.exec_update(<<~SQL.squish)
        UPDATE delivery_partnerships dp
        SET course_id = cc.course_id
        FROM course_cohorts cc
        WHERE cc.id = dp.course_cohort_id
          AND dp.course_id IS NULL
      SQL

      puts "Dry run: #{dry_run}"
      puts "Backfilled partnerships: #{backfilled}"
      puts "Removed duplicate partnerships: #{removed}"

      raise ActiveRecord::Rollback if dry_run
    end
  end
end
