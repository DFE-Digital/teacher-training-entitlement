class AddEcfIdToCourseCohorts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_column :course_cohorts, :ecf_id, :uuid, default: "gen_random_uuid()", null: false
    end
    add_index :course_cohorts, :ecf_id, unique: true, algorithm: :concurrently
  end
end
