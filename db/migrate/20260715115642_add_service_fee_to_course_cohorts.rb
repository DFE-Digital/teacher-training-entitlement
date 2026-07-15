class AddServiceFeeToCourseCohorts < ActiveRecord::Migration[8.1]
  def change
    add_column :course_cohorts, :service_fee, :decimal
  end
end
