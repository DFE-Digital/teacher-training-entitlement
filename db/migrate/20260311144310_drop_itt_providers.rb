class DropIttProviders < ActiveRecord::Migration[8.1]
  def change
    drop_table :itt_providers do |t|
      t.string :legal_name
      t.string :operating_name
      t.boolean :approved, default: false
      t.datetime :disabled_at
      t.datetime :removed_at
      t.timestamps
    end
  end
end
