class DropEligibilityList < ActiveRecord::Migration[8.1]
  def change
    drop_table :eligibility_list_entries do |t|
      t.string :identifier
      t.string :identifier_type
      t.string :type
      t.timestamps
    end
  end
end
