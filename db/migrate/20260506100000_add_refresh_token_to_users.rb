class AddRefreshTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :refresh_token, :text
    add_column :users, :refresh_token_updated_at, :datetime
    safety_assured do
      add_index :users, :refresh_token_updated_at
    end
  end
end
