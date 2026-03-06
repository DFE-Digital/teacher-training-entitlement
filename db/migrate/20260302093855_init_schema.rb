# frozen_string_literal: true

class InitSchema < ActiveRecord::Migration[8.1]
  def up
    load Rails.root.join("db/schema.rb")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
