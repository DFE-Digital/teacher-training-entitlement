class DropKindOfNursery < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :applications, :kind_of_nursery, :enum, enum_type: "kind_of_nurseries" }
    drop_enum :kind_of_nurseries
  end
end
