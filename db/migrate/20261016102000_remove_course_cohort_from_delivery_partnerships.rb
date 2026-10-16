class RemoveCourseCohortFromDeliveryPartnerships < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  OLD_UNIQUE_INDEX = "idx_delivery_partnerships_on_partner_provider_course_cohort".freeze
  NEW_UNIQUE_INDEX = "idx_delivery_partnerships_on_partner_provider_course".freeze

  def up
    unbackfilled = select_value("SELECT COUNT(*) FROM delivery_partnerships WHERE course_id IS NULL").to_i
    raise "Cannot remove course_cohort_id: #{unbackfilled} delivery partnerships have not been backfilled" if unbackfilled.positive?

    duplicates = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*) FROM (
        SELECT 1 FROM delivery_partnerships
        GROUP BY delivery_partner_id, lead_provider_id, course_id
        HAVING COUNT(*) > 1
      ) duplicates
    SQL
    if duplicates.positive?
      raise "Cannot remove course_cohort_id: #{duplicates} duplicate (delivery partner, lead provider, course) " \
            "combinations exist; run the data_migrations:backfill_course_delivery_partnerships rake task first"
    end

    validate_foreign_key :delivery_partnerships, :courses

    add_check_constraint :delivery_partnerships,
                         "course_id IS NOT NULL",
                         name: "delivery_partnerships_course_id_null",
                         validate: false
    validate_check_constraint :delivery_partnerships, name: "delivery_partnerships_course_id_null"
    change_column_null :delivery_partnerships, :course_id, false
    remove_check_constraint :delivery_partnerships, name: "delivery_partnerships_course_id_null"

    remove_index :delivery_partnerships, name: OLD_UNIQUE_INDEX, algorithm: :concurrently, if_exists: true
    remove_foreign_key :delivery_partnerships, :course_cohorts if foreign_key_exists?(:delivery_partnerships, :course_cohorts)
    remove_index :delivery_partnerships, :course_cohort_id, algorithm: :concurrently if index_exists?(:delivery_partnerships, :course_cohort_id)
    safety_assured { remove_column :delivery_partnerships, :course_cohort_id if column_exists?(:delivery_partnerships, :course_cohort_id) }

    add_index :delivery_partnerships,
              %i[delivery_partner_id lead_provider_id course_id],
              unique: true,
              name: NEW_UNIQUE_INDEX,
              algorithm: :concurrently
  end

  def down
    remove_index :delivery_partnerships, name: NEW_UNIQUE_INDEX, algorithm: :concurrently, if_exists: true

    change_column_null :delivery_partnerships, :course_id, true

    add_reference :delivery_partnerships,
                  :course_cohort,
                  null: true,
                  index: { algorithm: :concurrently },
                  foreign_key: false
    add_foreign_key :delivery_partnerships, :course_cohorts, validate: false

    add_index :delivery_partnerships,
              %i[delivery_partner_id lead_provider_id course_cohort_id],
              unique: true,
              name: OLD_UNIQUE_INDEX,
              algorithm: :concurrently
  end
end
