class AddAllocationToCourseCohortProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :course_cohort_providers, :allocation, :integer
  end
end
