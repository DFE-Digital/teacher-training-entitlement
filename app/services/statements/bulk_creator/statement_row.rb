module Statements
  class BulkCreator
    class StatementRow
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :start_date, :date
      attribute :deadline_date, :date
      attribute :payment_date, :date
      attribute :output_fee, :boolean, default: false

      validates :start_date, presence: true
      validates :deadline_date, presence: true
      validates :payment_date, presence: true

      def self.example_csv
        <<~CSV.strip
          start_date,deadline_date,payment_date,output_fee
          2025-02-01,2024-12-25,2025-01-26,true
          2025-03-01,2025-01-26,2025-02-27,false
          2025-04-01,2025-02-24,2025-03-25,false
        CSV
      end
    end
  end
end
