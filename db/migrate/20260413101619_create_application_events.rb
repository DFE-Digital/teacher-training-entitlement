class CreateApplicationEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :application_events do |t|
      t.references :application, null: false, foreign_key: true, index: true
      t.references :lead_provider, foreign_key: true, index: true
      t.string :event, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :application_events, :event
    add_index :application_events, :created_at
  end
end
