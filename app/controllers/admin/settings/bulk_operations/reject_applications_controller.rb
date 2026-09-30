module Admin::Settings::BulkOperations
  class RejectApplicationsController < BaseController
  private

    def bulk_operation_class
      BulkOperation::RejectApplications
    end

    def bulk_operation_index
      :admin_settings_bulk_operations_reject_applications
    end
  end
end
