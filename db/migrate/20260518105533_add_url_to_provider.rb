class AddUrlToProvider < ActiveRecord::Migration[8.1]
  def change
    add_column :lead_providers, :url, :string
  end
end
