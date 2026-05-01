class RemoveReasonForRejectionFromApplications < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :applications, :reason_for_rejection, :enum, enum_type: "reasons_for_rejection"
    end

    drop_enum :reasons_for_rejection
  end
end
