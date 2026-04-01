class RemoveLeadProviderApprovalStatusEnum < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :applications, :lead_provider_approval_status, :enum, enum_type: "lead_provider_approval_statuses" }
    drop_enum :lead_provider_approval_statuses
  end
end
