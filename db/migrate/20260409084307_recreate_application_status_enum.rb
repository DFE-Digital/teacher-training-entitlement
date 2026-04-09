class RecreateApplicationStatusEnum < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL
        ALTER TYPE application_statuses ADD VALUE 'superceded';
      SQL
    end
  end

  def down
    # no simple rollback
  end
end
