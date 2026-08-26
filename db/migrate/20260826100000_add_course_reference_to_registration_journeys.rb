class AddCourseReferenceToRegistrationJourneys < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :registration_journeys, :course, index: { algorithm: :concurrently }
  end
end
