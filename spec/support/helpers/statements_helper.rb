module Helpers
  module StatementsHelper
    extend ActiveSupport::Concern

    included do
      let(:statements_csv) { tempfile Statements::BulkCreator::StatementRow.example_csv }
      let(:contracts_csv)  { tempfile Statements::BulkCreator::ContractRow.example_csv }

      # examples use Course.first and Course.last
      before do
        Course.destroy_all
        create(:course, :npd_eirt)
      end
    end
  end
end
