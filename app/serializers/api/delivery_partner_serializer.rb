module API
  class DeliveryPartnerSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "delivery-partner" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      view :v1 do
        field(:name)
        field(:cohort) do |object, options|
          object.course_cohorts_for_lead_provider(options[:lead_provider])
                .map { |course_cohort| course_cohort.cohort.start_year }
                .uniq
                .sort
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
