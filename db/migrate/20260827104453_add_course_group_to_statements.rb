class AddCourseGroupToStatements < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :statements, :course_group, :enum, enum_type: :course_group

    remove_index :statements,
                 column: %i[lead_provider_id start_date frequency],
                 name: "index_statements_on_lead_provider_id_start_date_frequency",
                 algorithm: :concurrently

    add_index :statements,
              %i[lead_provider_id start_date frequency course_group],
              unique: true,
              name: "index_statements_on_lead_provider_period_course_group",
              algorithm: :concurrently
  end
end
