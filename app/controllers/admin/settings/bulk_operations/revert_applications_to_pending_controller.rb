module Admin::Settings::BulkOperations
  class RevertApplicationsToPendingController < BaseController
  private

    def bulk_operation_class
      BulkOperation::RevertApplicationsToPending
    end

    def bulk_operation_index
      :admin_settings_bulk_operations_revert_applications_to_pending_index
    end
  end
end
