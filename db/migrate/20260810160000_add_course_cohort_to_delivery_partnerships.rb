class AddCourseCohortToDeliveryPartnerships < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  UNIQUE_INDEX = "idx_delivery_partnerships_on_partner_provider_course_cohort".freeze

  def up
    add_reference :delivery_partnerships,
                  :course_cohort,
                  null: true,
                  index: { algorithm: :concurrently },
                  foreign_key: false
    add_foreign_key :delivery_partnerships, :course_cohorts, validate: false
    add_index :delivery_partnerships,
              %i[delivery_partner_id lead_provider_id course_cohort_id],
              unique: true,
              name: UNIQUE_INDEX,
              algorithm: :concurrently
    change_column_null :delivery_partnerships, :cohort_id, true
  end

  def down
    change_column_null :delivery_partnerships, :cohort_id, false
    remove_index :delivery_partnerships, name: UNIQUE_INDEX, algorithm: :concurrently
    remove_foreign_key :delivery_partnerships, :course_cohorts
    remove_index :delivery_partnerships, :course_cohort_id, algorithm: :concurrently
    remove_column :delivery_partnerships, :course_cohort_id
  end
end
