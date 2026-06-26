module API
  class ScheduleSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "schedule" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:course_identifier) { |schedule| schedule.cohort.course.identifier }
      field(:schedule_identifier, &:identifier)
      field(:cohort) { |schedule| schedule.cohort.start_year.to_s }
    end

    view :v1 do
      association :attributes, blueprint: AttributesSerializer do |cc|
        cc
      end
    end
  end
end
