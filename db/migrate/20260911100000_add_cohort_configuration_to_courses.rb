class AddCohortConfigurationToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :cohort_configuration, :jsonb, default: {}, null: false
  end
end
