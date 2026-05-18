class DropApplicationsWorksInChildcare < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :applications, :works_in_childcare } # rubocop:disable Rails/ReversibleMigration
  end
end
