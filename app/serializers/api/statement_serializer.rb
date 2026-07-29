module API
  class StatementSerializer < Blueprinter::Base
    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:start_date, datetime_format: "%Y-%m-%d")
      field :deadline_date, name: :cut_off_date, datetime_format: "%Y-%m-%d"
      field :payment_date, datetime_format: "%Y-%m-%d"
      field(:paid?, name: :paid)
      field :created_at
      field :updated_at
    end

    identifier :ecf_id, name: :id
    field(:type) { "statement" }

    association :attributes, blueprint: AttributesSerializer do |statement|
      statement
    end
  end
end
