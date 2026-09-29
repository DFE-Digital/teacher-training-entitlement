module Admin::Settings::BulkOperations
  class BackfillDeclarationDeliveryPartnersController < BaseController
  private

    def bulk_operation_class
      BulkOperation::BackfillDeclarationDeliveryPartners
    end

    def bulk_operation_index
      :admin_settings_bulk_operations_backfill_declaration_delivery_partners
    end
  end
end
