class RemoveCohortFromDeliveryPartnerships < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  OLD_UNIQUE_INDEX = "idx_on_delivery_partner_id_lead_provider_id_cohort__10d5da32cd".freeze

  def up
    unbackfilled = select_value("SELECT COUNT(*) FROM delivery_partnerships WHERE course_cohort_id IS NULL").to_i
    raise "Cannot remove cohort_id: #{unbackfilled} delivery partnerships have not been backfilled" if unbackfilled.positive?

    add_check_constraint :delivery_partnerships,
                         "course_cohort_id IS NOT NULL",
                         name: "delivery_partnerships_course_cohort_id_null",
                         validate: false
    validate_check_constraint :delivery_partnerships, name: "delivery_partnerships_course_cohort_id_null"
    change_column_null :delivery_partnerships, :course_cohort_id, false
    remove_check_constraint :delivery_partnerships, name: "delivery_partnerships_course_cohort_id_null"

    remove_foreign_key :delivery_partnerships, :cohorts
    remove_index :delivery_partnerships, name: OLD_UNIQUE_INDEX, algorithm: :concurrently
    remove_index :delivery_partnerships, :cohort_id, algorithm: :concurrently
    safety_assured { remove_column :delivery_partnerships, :cohort_id }
  end

  def down
    add_reference :delivery_partnerships, :cohort, null: true, index: false, foreign_key: false

    safety_assured do
      execute <<~SQL.squish
        UPDATE delivery_partnerships
        SET cohort_id = course_cohorts.cohort_id
        FROM course_cohorts
        WHERE course_cohorts.id = delivery_partnerships.course_cohort_id
      SQL

      execute <<~SQL.squish
        DELETE FROM delivery_partnerships duplicate
        USING delivery_partnerships original
        WHERE duplicate.delivery_partner_id = original.delivery_partner_id
          AND duplicate.lead_provider_id = original.lead_provider_id
          AND duplicate.cohort_id = original.cohort_id
          AND duplicate.id > original.id
      SQL
    end

    change_column_null :delivery_partnerships, :cohort_id, false
    add_index :delivery_partnerships,
              %i[delivery_partner_id lead_provider_id cohort_id],
              unique: true,
              name: OLD_UNIQUE_INDEX,
              algorithm: :concurrently
    add_index :delivery_partnerships, :cohort_id, algorithm: :concurrently
    add_foreign_key :delivery_partnerships, :cohorts, validate: false
    validate_foreign_key :delivery_partnerships, :cohorts

    change_column_null :delivery_partnerships, :course_cohort_id, true
  end
end
