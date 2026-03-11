class AddApplicationStiCols < ActiveRecord::Migration[8.1]
  def change
    add_column :applications, :type, :string
  end
end
