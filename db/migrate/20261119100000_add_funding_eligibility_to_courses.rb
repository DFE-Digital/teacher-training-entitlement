class AddFundingEligibilityToCourses < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      add_column :courses, :funding_eligibility, :string
      execute "UPDATE courses SET funding_eligibility = 'state_funded_school'"
      change_column_null :courses, :funding_eligibility, false
    end
  end

  def down
    safety_assured { remove_column :courses, :funding_eligibility }
  end
end
