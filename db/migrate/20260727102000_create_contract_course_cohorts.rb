class CreateContractCourseCohorts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    create_table :contract_course_cohorts do |t|
      t.references :contract, null: false, index: false
      t.references :course_cohort, null: false, index: false

      t.timestamps
    end

    add_foreign_key :contract_course_cohorts, :contracts, validate: false
    add_foreign_key :contract_course_cohorts, :course_cohorts, validate: false
    add_index :contract_course_cohorts, :contract_id, algorithm: :concurrently
    add_index :contract_course_cohorts, :course_cohort_id, algorithm: :concurrently
    add_index :contract_course_cohorts,
              %i[contract_id course_cohort_id],
              unique: true,
              algorithm: :concurrently
  end
end
