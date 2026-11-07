module API
  class DeliveryPartnerSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "delivery-partner" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      view :v1 do
        field(:name)
        field(:cohort) do |object, options|
          options[:cohort_start_years_by_delivery_partner].fetch(object.id, [])
        end
        field(:created_at)
        field(:updated_at)
      end
    end

    view :v1 do
      association :attributes, blueprint: AttributesSerializer, view: :v1 do |delivery_partner|
        delivery_partner
      end
    end
  end
end
