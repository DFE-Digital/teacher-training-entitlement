class AddCourseToDeliveryPartnerships < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :delivery_partnerships,
                  :course,
                  null: true,
                  index: { algorithm: :concurrently },
                  foreign_key: false
    add_foreign_key :delivery_partnerships, :courses, validate: false
  end
end
